#!/usr/bin/env python3
"""Idle-cost arithmetic for the demo shape in environments/demo.tfvars.example.

Rates are the published ones recorded in the README. This script only multiplies
them. It does not call AWS and it does not invent a traffic volume.
"""

HOURS_PER_DAY = 24
HOURS_PER_MONTH = 730  # 365 / 12 * 24
SECONDS_PER_MONTH = HOURS_PER_MONTH * 3600
SECONDS_PER_DAY = HOURS_PER_DAY * 3600

# https://aws.amazon.com/fargate/pricing/ Linux/ARM examples, US East (N. Virginia).
FARGATE_ARM_VCPU_PER_SECOND = 0.0000089944
FARGATE_ARM_GB_PER_SECOND = 0.0000009889

# https://aws.amazon.com/elasticloadbalancing/pricing/ US-East-1 examples.
ALB_PER_HOUR = 0.0225
ALB_LCU_PER_HOUR = 0.008

# AWS Price List, Amazon EC2 NAT gateway map, US East (N. Virginia), read 17 Nov 2026.
# https://b0.p.awsstatic.com/pricing/2.0/meteredUnitMaps/ec2/USD/current/natgateway.json
NAT_PER_HOUR = 0.045
NAT_PER_GB = 0.045

# AWS Price List offer AmazonVPC 20261117011403, us-east-1.
# USE1-PublicIPv4:InUseAddress
IPV4_PER_HOUR = 0.005

# https://aws.amazon.com/kms/pricing/ one customer managed key, before any rotation surcharge.
KMS_PER_MONTH = 1.0

# AWS Price List offer AmazonVPC 20261117011403, USE1-VpcEndpoint-Hours.
INTERFACE_ENDPOINT_PER_HOUR = 0.01


def money(value: float) -> str:
    return f"{value:.4f}"


def fargate(vcpu: float, memory_gb: float, seconds: int) -> float:
    return (
        vcpu * FARGATE_ARM_VCPU_PER_SECOND * seconds
        + memory_gb * FARGATE_ARM_GB_PER_SECOND * seconds
    )


def idle(tasks: int, vcpu: float, memory_gb: float, nat_gateways: int, public_ipv4: int, seconds: int) -> dict:
    hours = seconds / 3600
    parts = {
        "fargate": tasks * fargate(vcpu, memory_gb, seconds),
        "alb": ALB_PER_HOUR * hours,
        "nat": NAT_PER_HOUR * nat_gateways * hours,
        "ipv4": IPV4_PER_HOUR * public_ipv4 * hours,
        "kms": KMS_PER_MONTH * hours / HOURS_PER_MONTH,
    }
    parts["total"] = sum(parts.values())
    return parts


def main() -> None:
    demo_day = idle(1, 0.25, 0.5, 1, 3, SECONDS_PER_DAY)
    demo_month = idle(1, 0.25, 0.5, 1, 3, SECONDS_PER_MONTH)
    prod_day = idle(2, 0.5, 1.0, 2, 4, SECONDS_PER_DAY)
    prod_month = idle(2, 0.5, 1.0, 2, 4, SECONDS_PER_MONTH)
    endpoint_month = 3 * 2 * INTERFACE_ENDPOINT_PER_HOUR * HOURS_PER_MONTH

    print("demo day", {k: money(v) for k, v in demo_day.items()})
    print("demo month", {k: money(v) for k, v in demo_month.items()})
    print("production day", {k: money(v) for k, v in prod_day.items()})
    print("production month", {k: money(v) for k, v in prod_month.items()})
    print("three interface endpoints in two AZs, hours only", money(endpoint_month))


if __name__ == "__main__":
    main()
