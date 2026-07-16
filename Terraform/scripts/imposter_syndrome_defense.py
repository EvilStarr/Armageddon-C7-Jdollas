# impostor_syndrome_defense.py
# python3 impostor_syndrome_defense.py

import random
import time

skills = [
    "Lambda",
    "IAM",
    "Terraform",
    "API Gateway",
    "WAF",
    "CloudWatch",
    "DynamoDB",
    "EventBridge",
    "Bedrock",
    "Cognito",
    "RBAC",
]

truths = [
    "You are not behind. You are building.",
    "Confusion is not failure. Confusion is the start of learning.",
    "Errors are not insults. They are instructions.",
    "CloudWatch is not judging you. It is helping you.",
    "Terraform errors look scary because Terraform has no bedside manner.",
    "IAM denied you because IAM is doing its job.",
    "If you debugged it, you learned it.",
    "If you broke it and fixed it, you own it.",
    "You are allowed to be new and still be serious.",
    "You do not need to know everything. You need to know how to investigate.",
]

warnings = [
    "Do not compare your chapter 2 to someone else's chapter 20.",
    "Do not let one failed apply define your engineering future.",
    "Do not confuse discomfort with incompetence.",
    "Do not outsource your thinking to AI.",
    "Do not panic. Read the logs.",
]

def print_slow(text, delay=0.03):
    for char in text:
        print(char, end="", flush=True)
        time.sleep(delay)
    print()

def main():
    print("\n=== IMPOSTOR SYNDROME DEFENSE SYSTEM ===\n")
    name = input("Enter your name: ").strip() or "Engineer"

    print_slow(f"\nScanning {name}'s cloud engineering progress...\n")

    time.sleep(1)

    learned = random.sample(skills, k=random.randint(4, len(skills)))

    print("Detected skills:")
    for skill in learned:
        print(f"  ✅ {skill}")
        time.sleep(0.2)

    print("\nThreat detected: Impostor Syndrome")
    time.sleep(1)

    print("\nDeploying countermeasures...\n")
    time.sleep(1)

    print_slow(random.choice(truths))
    print_slow(random.choice(truths))
    print_slow(random.choice(warnings))

    print("\nFinal assessment:")
    print(f"✅ {name}, you are not an impostor.")
    print("✅ You are a student becoming an engineer.")
    print("✅ Keep building.\n")

    print("Broken Theo says: Read the logs. Then win.\n")

if __name__ == "__main__":
    main()

if terraform_apply == "FAILED":
    print("Good.")
    print("Now you're about to learn something.")

print("Reading CloudWatch Logs...")

time.sleep(2)

print("Diagnosis:")

print("The problem is not AWS.")
print("The problem is you.")
print("...but that's good news because you can fix you.")

print("Checking engineering status...")

time.sleep(2)

print("Impostor Syndrome: DETECTED")

time.sleep(1)

print("Reviewing evidence...\n")

evidence = [
    "Completed Kubernetes labs.",
    "Built Terraform deployments.",
    "Configured IAM policies.",
    "Implemented Cognito authentication.",
    "Protected an API with WAF.",
    "Integrated Amazon Bedrock.",
    "Debugged Lambda failures.",
    "Read CloudWatch logs."
]

for item in evidence:
    print(f"✔ {item}")
    time.sleep(0.4)

print("\nConclusion:")
print("Engineering competence confirmed.")
print("Impostor Syndrome rejected.")

def ask_ai():
    print("Consulting AI...")
    time.sleep(2)

    print("\nAI Response:")
    print("No.")
    print("Go read the documentation first.")