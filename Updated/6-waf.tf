resource "aws_wafv2_web_acl" "waf" {
  name  = "jdollas_waf"
  scope = "REGIONAL"
  default_action {
    allow {}
  }

  visibility_config {
    cloudwatch_metrics_enabled = true  # wheter the resource sends metrics to cloudwatch
    metric_name                = "waf" # name of the cloudwatch metric
    sampled_requests_enabled   = true  # store samplings of requests that match the rules
  }

  # Prevent Terraform from managing inline rules -- prevents terraform from trying to overwrite rules managed externally to avoid state drift
  lifecycle {
    ignore_changes = [rule]
  }
}

resource "aws_wafv2_web_acl_rule" "common_rule" {
  name        = "AWSCommonRules"
  web_acl_arn = aws_wafv2_web_acl.waf.arn
  priority    = 30
  override_action {
    none {}
  }

  statement {
    managed_rule_group_statement {
      name        = "AWSManagedRulesCommonRuleSet"
      vendor_name = "AWS"
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "commonRules"
    sampled_requests_enabled   = true
  }
}

# https://docs.aws.amazon.com/waf/latest/APIReference/API_GeoMatchStatement.html
resource "aws_wafv2_web_acl_rule" "geo_rule" {
  name        = "block-sa-countries"
  web_acl_arn = aws_wafv2_web_acl.waf.arn
  priority    = 2
  action {
    block {}
  }

  statement {
    geo_match_statement {
      country_codes = ["CO", "AR", "BR"]
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true # enable metrics for this rule
    metric_name                = "block-countries"
    sampled_requests_enabled   = true # store sample requests that match the rule
  }
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/wafv2_web_acl_rule#rate-based-statement
# https://docs.aws.amazon.com/waf/latest/APIReference/API_RateBasedStatement.html
resource "aws_wafv2_web_acl_rule" "rate_limit_rule" {
  name        = "rate-limit-by-ip"
  web_acl_arn = aws_wafv2_web_acl.waf.arn
  priority    = 10
  action {
    block {}
  }

  statement {
    rate_based_statement {
      limit              = 10
      aggregate_key_type = "IP"
      # remember this doesn't mean check every 60 secs, it looks back 60 secs so a burst of traffic might make it through
      evaluation_window_sec = 60 # consider requests in the 60 second window when evaluating the rule
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "rate-limit"
    sampled_requests_enabled   = true
  }
}

# attach waf to api gateway
resource "aws_wafv2_web_acl_association" "api_waf_association" {
  resource_arn = aws_api_gateway_stage.prod.arn # associate with the stage not the gw because security requirements may differ between stages
  web_acl_arn  = aws_wafv2_web_acl.waf.arn
}

# logging to s3
resource "aws_cloudwatch_log_group" "waf_log_group" {
  name = "aws-waf-logs-jdollas"
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/wafv2_web_acl_logging_configuration
resource "aws_wafv2_web_acl_logging_configuration" "waf_logging_config" {
  log_destination_configs = [aws_cloudwatch_log_group.waf_log_group.arn]
  resource_arn            = aws_wafv2_web_acl.waf.arn
}

resource "aws_cloudwatch_log_resource_policy" "waf_log_policy" {
  policy_document = data.aws_iam_policy_document.waf_log_policy_doc.json
  policy_name     = "waf-log-policy"
}

# waf.tf -- Lambda-protective WAF rules
# WAF cannot attach directly to Lambda — it attaches to the API Gateway stage
# that sits in front of your Lambda functions. These rules protect your
# python_lambda and node_lambda endpoints from abuse patterns that are
# especially relevant for AI/LLM-style backends (cost explosions, flooding,
# known bad inputs). All rules attach to the existing aws_wafv2_web_acl.waf ACL.

# ---------------------------------------------------------------------------
# Rule 1: Block SQL Injection attempts targeting Lambda query params
# Priority 20 -- runs after geo-block (2) and rate-limit (10), before common rules (30)
# Protects your /python?name= and /node?name= query string params from injection
# ---------------------------------------------------------------------------
resource "aws_wafv2_web_acl_rule" "sql_injection_rule" {
  name        = "block-sql-injection"
  web_acl_arn = aws_wafv2_web_acl.waf.arn
  priority    = 20

  action {
    block {}
  }

  statement {
    sqli_match_statement {
      field_to_match {
        query_string {}
      }
      text_transformation {
        priority = 1
        type     = "URL_DECODE"
      }
      text_transformation {
        priority = 2
        type     = "HTML_ENTITY_DECODE"
      }
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "block-sql-injection"
    sampled_requests_enabled   = true
  }
}

# ---------------------------------------------------------------------------
# Rule 2: Block oversized request bodies
# Priority 25 -- critical for Lambda because large payloads = longer execution
# time = higher cost. Blocks any request body over 8KB.
# ---------------------------------------------------------------------------
resource "aws_wafv2_web_acl_rule" "large_body_rule" {
  name        = "block-large-body"
  web_acl_arn = aws_wafv2_web_acl.waf.arn
  priority    = 25

  action {
    block {}
  }

  statement {
    size_constraint_statement {
      field_to_match {
        body {
          oversize_handling = "MATCH" # treat oversized body as a match → block it
        }
      }
      comparison_operator = "GT"
      size                = 8192 # 8KB — adjust upward if your Lambda legitimately accepts large payloads
      text_transformation {
        priority = 0
        type     = "NONE"
      }
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "block-large-body"
    sampled_requests_enabled   = true
  }
}

# ---------------------------------------------------------------------------
# Rule 3: Per-user rate limit via Cognito JWT sub claim
# Priority 15 -- runs after geo-block (2) and IP rate-limit (10)
# Your existing rate limit is per IP, which doesn't protect against distributed
# abuse where one authenticated user spreads requests across many IPs (e.g., 
# VPN hopping). This rule limits per JWT sub claim instead — 50 requests per
# 5-minute window per authenticated user regardless of IP.
# ---------------------------------------------------------------------------
resource "aws_wafv2_web_acl_rule" "per_user_rate_limit_rule" {
  name        = "rate-limit-by-jwt-user"
  web_acl_arn = aws_wafv2_web_acl.waf.arn
  priority    = 15

  action {
    block {}
  }

  statement {
    rate_based_statement {
      limit                 = 50   # max requests per evaluation window per user
      aggregate_key_type    = "CUSTOM_KEYS"
      evaluation_window_sec = 300  # 5-minute window

      custom_keys{
        header {
          name = "Authorization" # JWT access token is passed here by your Cognito authorizer
          text_transformation {
            priority = 0
            type     = "NONE"
          }
        }
      }
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "rate-limit-per-user"
    sampled_requests_enabled   = true
  }
}

# ---------------------------------------------------------------------------
# Rule 4: AWS Managed Known Bad Inputs ruleset
# Priority 35 -- runs after common rules (30)
# Blocks requests with patterns known to exploit vulnerabilities in web apps —
# includes Log4j (Log4JRCE), SSRF attempts, and JavaDeserializationExploits.
# Directly relevant since your Lambda runtimes (Python 3.11, Node 24) can be
# targeted by these payloads via query strings or request bodies.
# ---------------------------------------------------------------------------
resource "aws_wafv2_web_acl_rule" "known_bad_inputs_rule" {
  name        = "block-known-bad-inputs"
  web_acl_arn = aws_wafv2_web_acl.waf.arn
  priority    = 35

  override_action {
    none {} # enforce the managed rule group's built-in actions (block)
  }

  statement {
    managed_rule_group_statement {
      name        = "AWSManagedRulesKnownBadInputsRuleSet"
      vendor_name = "AWS"
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "known-bad-inputs"
    sampled_requests_enabled   = true
  }
}

# ---------------------------------------------------------------------------
# New WAF log group -- separate from the existing waf_log_group so Lambda
# functions can reference it directly via the WAF_LOG_GROUP env var without
# coupling to the original logging resource.
# Name must start with "aws-waf-logs-" — AWS enforces this for WAF log destinations.
# ---------------------------------------------------------------------------
resource "aws_cloudwatch_log_group" "waf_logs" {
  name              = "aws-waf-logs-jdollas-lambda"
  retention_in_days = 7 # adjust to match your compliance/audit requirements
}

# WAF_LOG_GROUP is injected into both Lambda functions via the environment
# block in 3-lambda.tf, referencing aws_cloudwatch_log_group.waf_logs below.
