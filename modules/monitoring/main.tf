/**
 * Cloud Monitoring module for i4g operational alerting.
 *
 * Creates:
 *  - Notification channel (email)
 *  - Log-based metrics for alert events
 *  - Alert policies for PII access, ingestion failures, and dossier jobs
 */

variable "project_id" {
  description = "GCP project ID."
  type        = string
}

variable "notification_email" {
  description = "Email address for alert notifications."
  type        = string
}

variable "detokenization_threshold" {
  description = "Max detokenization alert events per hour before firing."
  type        = number
  default     = 5
}

variable "ingestion_alert_threshold" {
  description = "Number of ingestion failure alert events per hour before firing."
  type        = number
  default     = 1
}

variable "dossier_alert_threshold" {
  description = "Number of dossier stuck/failure events per hour before firing."
  type        = number
  default     = 1
}

# ---------------------------------------------------------------------------
# Notification channel
# ---------------------------------------------------------------------------

resource "google_monitoring_notification_channel" "email" {
  project      = var.project_id
  display_name = "i4g Ops Email"
  type         = "email"

  labels = {
    email_address = var.notification_email
  }
}

# ---------------------------------------------------------------------------
# Log-based metrics
# ---------------------------------------------------------------------------

resource "google_logging_metric" "pii_access_alert" {
  project     = var.project_id
  name        = "i4g/pii_access_alert"
  description = "Counts PII detokenization threshold-exceeded events."
  filter      = "jsonPayload.alert=true AND jsonPayload.alert_type=\"pii_access\""

  metric_descriptor {
    metric_kind = "DELTA"
    value_type  = "INT64"
    unit        = "1"
  }
}

resource "google_logging_metric" "ingestion_failure_alert" {
  project     = var.project_id
  name        = "i4g/ingestion_failure_alert"
  description = "Counts ingestion error-rate-exceeded alert events."
  filter      = "jsonPayload.alert=true AND jsonPayload.alert_type=\"ingestion_failure\""

  metric_descriptor {
    metric_kind = "DELTA"
    value_type  = "INT64"
    unit        = "1"
  }
}

resource "google_logging_metric" "dossier_alert" {
  project     = var.project_id
  name        = "i4g/dossier_alert"
  description = "Counts dossier stuck or failure alert events."
  filter      = "jsonPayload.alert=true AND (jsonPayload.alert_type=\"dossier_stuck\" OR jsonPayload.alert_type=\"dossier_failure\")"

  metric_descriptor {
    metric_kind = "DELTA"
    value_type  = "INT64"
    unit        = "1"
  }
}

# ---------------------------------------------------------------------------
# Alert policies
# ---------------------------------------------------------------------------

resource "google_monitoring_alert_policy" "pii_access" {
  project      = var.project_id
  display_name = "PII Detokenization Access Alert"
  combiner     = "OR"

  conditions {
    display_name = "PII access threshold exceeded"

    condition_threshold {
      filter          = "metric.type=\"logging.googleapis.com/user/${google_logging_metric.pii_access_alert.name}\""
      comparison      = "COMPARISON_GT"
      threshold_value = var.detokenization_threshold
      duration        = "0s"

      aggregations {
        alignment_period   = "3600s"
        per_series_aligner = "ALIGN_SUM"
      }
    }
  }

  notification_channels = [google_monitoring_notification_channel.email.id]

  documentation {
    content   = "A user exceeded the PII detokenization rate threshold. Investigate in Cloud Logging with filter: `jsonPayload.alert_type=\"pii_access\"`."
    mime_type = "text/markdown"
  }
}

resource "google_monitoring_alert_policy" "ingestion_failure" {
  project      = var.project_id
  display_name = "Ingestion Failure Rate Alert"
  combiner     = "OR"

  conditions {
    display_name = "Ingestion error rate exceeded"

    condition_threshold {
      filter          = "metric.type=\"logging.googleapis.com/user/${google_logging_metric.ingestion_failure_alert.name}\""
      comparison      = "COMPARISON_GT"
      threshold_value = var.ingestion_alert_threshold
      duration        = "0s"

      aggregations {
        alignment_period   = "3600s"
        per_series_aligner = "ALIGN_SUM"
      }
    }
  }

  notification_channels = [google_monitoring_notification_channel.email.id]

  documentation {
    content   = "Ingestion error rate exceeded. Check recent ingestion runs in Cloud Logging: `jsonPayload.alert_type=\"ingestion_failure\"`."
    mime_type = "text/markdown"
  }
}

resource "google_monitoring_alert_policy" "dossier_stuck" {
  project      = var.project_id
  display_name = "Dossier Generation Alert"
  combiner     = "OR"

  conditions {
    display_name = "Dossier stuck or failed"

    condition_threshold {
      filter          = "metric.type=\"logging.googleapis.com/user/${google_logging_metric.dossier_alert.name}\""
      comparison      = "COMPARISON_GT"
      threshold_value = var.dossier_alert_threshold
      duration        = "0s"

      aggregations {
        alignment_period   = "3600s"
        per_series_aligner = "ALIGN_SUM"
      }
    }
  }

  notification_channels = [google_monitoring_notification_channel.email.id]

  documentation {
    content   = "A dossier/report generation job is stuck or failed. Check Cloud Logging: `jsonPayload.alert_type=\"dossier_stuck\" OR jsonPayload.alert_type=\"dossier_failure\"`."
    mime_type = "text/markdown"
  }
}
