#!/usr/bin/env python3
"""Render docs/architecture.png. Requires the graphviz `dot` binary."""

import shutil
import subprocess
from pathlib import Path

DOT = r"""
digraph secure_aws_platform {
  rankdir=TB;
  bgcolor="white";
  pad=0.35;
  nodesep=0.35;
  ranksep=0.55;
  fontname="Helvetica";
  node [shape=box, style="rounded,filled", fontname="Helvetica", fontsize=12, color="#334155", fillcolor="#f8fafc"];
  edge [color="#475569", fontname="Helvetica", fontsize=10, arrowsize=0.7];

  browser [label="Browser", fillcolor="#e2e8f0"];

  subgraph cluster_vpc {
    label="VPC  10.40.0.0/16    default security group, route table, and NACL closed";
    color="#64748b";
    fontname="Helvetica";
    fontsize=12;
    style="rounded";

    subgraph cluster_public {
      label="Public subnets    no auto-assigned public IPs";
      color="#0369a1";
      fontname="Helvetica";
      style="rounded";
      igw [label="Internet gateway", fillcolor="#e0f2fe"];
      alb [label="Application Load Balancer", fillcolor="#e0f2fe"];
      nat [label="NAT gateway", fillcolor="#e0f2fe"];
    }

    subgraph cluster_private {
      label="Private subnets    tasks have no public IP";
      color="#15803d";
      fontname="Helvetica";
      style="rounded";
      tasks [label="ECS Fargate\nsample container", fillcolor="#dcfce7"];
      s3ep [label="S3 gateway endpoint", fillcolor="#dcfce7"];
    }
  }

  flow [label="VPC flow logs\nS3 + customer key", fillcolor="#fef3c7"];
  alblogs [label="ALB access logs\nS3 + SSE-S3", fillcolor="#fef3c7"];
  cw [label="CloudWatch alarms\nand dashboard", fillcolor="#fae8ff"];
  sns [label="Email via SNS", fillcolor="#fae8ff"];
  kms [label="KMS key\nrotation on", fillcolor="#fee2e2"];
  budget [label="AWS Budgets\nwhole account", fillcolor="#fae8ff"];

  browser -> igw [label="HTTP, or HTTPS with a certificate"];
  igw -> alb;
  alb -> tasks [label="container port only"];
  tasks -> s3ep [label="tcp/443"];
  tasks -> nat [label="tcp/443"];
  nat -> igw [label="egress", constraint=false];

  {rank=same; flow; alblogs; kms}
  tasks -> flow [style=dashed];
  alb -> alblogs [style=dashed];
  kms -> flow [style=dotted, label="encrypt"];
  kms -> cw [style=dotted];
  tasks -> cw [style=dashed];
  alb -> cw [style=dashed];
  cw -> sns;
}
"""


def main() -> None:
    if shutil.which("dot") is None:
        raise SystemExit("graphviz dot is not installed")
    here = Path(__file__).parent
    for kind, name in (("png", "architecture.png"), ("svg", "architecture.svg")):
        out = here / name
        subprocess.run(
            ["dot", f"-T{kind}", "-o", str(out)],
            input=DOT,
            text=True,
            check=True,
        )
        print(out)


if __name__ == "__main__":
    main()
