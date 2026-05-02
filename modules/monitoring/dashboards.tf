resource "google_monitoring_dashboard" "phishdestroy_slo" {
  project = var.project_id
  dashboard_json = jsonencode({
    displayName = "PhishDestroy SLO Dashboard"
    gridLayout = {
      columns = 2
      widgets = [
        {
          title = "Per-service daily-quota utilisation"
          xyChart = {
            dataSets = [
              {
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "metric.type=\"logging.googleapis.com/user/i4g/provider_quota_usage\" resource.type=\"cloud_run_job\""
                  }
                }
              }
            ]
          }
        },
        {
          title = "p50 ingest-to-enqueue latency (< 60s)"
          xyChart = {
            dataSets = [
              {
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "metric.type=\"logging.googleapis.com/user/i4g/ingest_latency\" resource.type=\"cloud_run_job\""
                  }
                }
              }
            ]
          }
        },
        {
          title = "Parse-failure rate per team (< 1%)"
          xyChart = {
            dataSets = [
              {
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "metric.type=\"logging.googleapis.com/user/i4g/parse_failure_rate\" resource.type=\"cloud_run_job\""
                  }
                }
              }
            ]
          }
        },
        {
          title = "Blocklist-aggregator source health (8/8 up)"
          xyChart = {
            dataSets = [
              {
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "metric.type=\"logging.googleapis.com/user/i4g/blocklist_source_health\" resource.type=\"cloud_run_job\""
                  }
                }
              }
            ]
          }
        }
      ]
    }
  })
}
