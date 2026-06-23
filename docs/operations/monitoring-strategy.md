# Monitoring Strategy

## Overview

This document describes the monitoring approach for the AWS Production Web Platform.

Monitoring is designed to provide visibility into application availability, infrastructure health, performance, and operational events.

The monitoring strategy focuses on:

* Service availability
* Resource health
* Capacity management
* Performance monitoring
* Operational alerting
* Incident detection

The objective is to reduce mean time to detection (MTTD) and improve operational visibility.

---

# Monitoring Architecture

Monitoring data is collected from AWS managed services and application infrastructure.

```text
AWS Resources
      |
      v
CloudWatch Metrics
      |
      v
CloudWatch Alarms
      |
      v
Operations Team
```

---

# Monitoring Objectives

The platform should provide visibility into:

## Availability

Questions answered:

* Is the application reachable?
* Are requests succeeding?
* Are targets healthy?

---

## Performance

Questions answered:

* Is latency increasing?
* Are requests slowing down?
* Is the database under stress?

---

## Capacity

Questions answered:

* Is Auto Scaling required?
* Are resources approaching limits?
* Is utilization increasing?

---

## Security Visibility

Questions answered:

* Are infrastructure changes occurring?
* Are unauthorized actions occurring?
* Are resources drifting from expected configuration?

---

# Application Load Balancer Monitoring

## Metrics

Monitor:

* RequestCount
* TargetResponseTime
* HTTPCode_ELB_5XX_Count
* HTTPCode_Target_5XX_Count
* UnHealthyHostCount

---

## Example Alerts

### Unhealthy Targets

Alarm Condition:

```text
UnHealthyHostCount > 0
```

Reason:

Application instances are failing health checks.

Impact:

Traffic may not be routed correctly.

---

### Increased 5XX Errors

Alarm Condition:

```text
HTTPCode_ELB_5XX_Count > 0
```

Reason:

Load balancer or application failures.

Impact:

Users may experience errors.

---

# EC2 Monitoring

## Metrics

Monitor:

* CPUUtilization
* StatusCheckFailed
* NetworkIn
* NetworkOut
* DiskReadOps
* DiskWriteOps

---

## Example Alerts

### High CPU Utilization

Alarm Condition:

```text
CPUUtilization > 80%
for 5 minutes
```

Reason:

Application load increase.

Possible Actions:

* Review scaling activity
* Investigate application performance

---

### Instance Status Check Failure

Alarm Condition:

```text
StatusCheckFailed > 0
```

Reason:

Infrastructure or operating system issue.

Impact:

Instance may require replacement.

---

# Auto Scaling Monitoring

## Metrics

Monitor:

* GroupDesiredCapacity
* GroupInServiceInstances
* GroupPendingInstances
* GroupTerminatingInstances

---

## Example Alerts

### Capacity Mismatch

Alarm Condition:

```text
InServiceInstances < DesiredCapacity
```

Reason:

Instances are failing to launch or register.

Impact:

Reduced application availability.

---

# Aurora Monitoring

## Metrics

Monitor:

* CPUUtilization
* DatabaseConnections
* FreeStorageSpace
* ReadLatency
* WriteLatency

---

## Example Alerts

### High Database Connections

Alarm Condition:

```text
DatabaseConnections > threshold
```

Reason:

Application demand increase.

Impact:

Potential connection exhaustion.

---

### High Read Latency

Alarm Condition:

```text
ReadLatency exceeds baseline
```

Reason:

Database performance degradation.

Impact:

Application response delays.

---

# Networking Monitoring

## NAT Gateway

Monitor:

* BytesIn
* BytesOut
* PacketsIn
* PacketsOut

Purpose:

Validate outbound connectivity for private resources.

---

## Internet Gateway

Internet Gateway availability is monitored indirectly through:

* ALB reachability
* Application availability
* End-user traffic success

---

# Operational Dashboards

Recommended CloudWatch dashboard sections:

## Availability

Display:

* ALB request count
* Healthy targets
* HTTP response codes

---

## Compute

Display:

* EC2 CPU utilization
* EC2 health status
* Auto Scaling capacity

---

## Database

Display:

* Aurora CPU utilization
* Connections
* Latency metrics

---

## Networking

Display:

* NAT Gateway traffic
* Load balancer throughput

---

# Logging Strategy

Recommended log sources:

## CloudTrail

Purpose:

* API auditing
* Change tracking
* Security investigations

---

## CloudWatch Logs

Purpose:

* Application logs
* System logs
* Operational troubleshooting

---

## VPC Flow Logs

Purpose:

* Network troubleshooting
* Traffic analysis
* Security investigations

---

# Incident Detection

Monitoring should identify:

* Unhealthy application instances
* Failed health checks
* Scaling failures
* Database connectivity issues
* Elevated error rates
* Infrastructure changes

Detected events should trigger operational investigation using:

```text
operational-runbook.md
incident-scenarios.md
```

---

# Future Monitoring Improvements

Potential enhancements:

* SNS alert notifications
* EventBridge integrations
* CloudWatch anomaly detection
* AWS Config compliance monitoring
* GuardDuty security findings
* Centralized observability platform
* Distributed tracing

---

# Success Criteria

The monitoring platform should:

* Detect infrastructure failures
* Detect application failures
* Detect database issues
* Detect scaling problems
* Provide operational visibility
* Support rapid incident response

---

# Summary

Monitoring is a critical component of operating production infrastructure.

The monitoring strategy focuses on visibility, alerting, and operational awareness across the application, compute, database, and networking layers.

Effective monitoring reduces detection time, improves troubleshooting, and supports reliable service operation.