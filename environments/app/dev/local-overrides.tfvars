# Local overrides for dev environment (do not commit secrets here)
iap_project_level_bindings = false

streamlit_env_vars = {
  I4G_ENV                          = "dev"
  I4G_API__KEY                     = "dev-analyst-token"
  STREAMLIT_SERVER_TITLE           = "i4g Analyst Dashboard"
  I4G_VERTEX_SEARCH_PROJECT        = "i4g-dev"
  I4G_VERTEX_SEARCH_LOCATION       = "global"
  I4G_VERTEX_SEARCH_DATA_STORE     = "retrieval-poc"
  I4G_VERTEX_SEARCH_SERVING_CONFIG = "default_search"
}

console_env_vars = {
  NEXT_PUBLIC_USE_MOCK_DATA        = "false"
  I4G_API_KIND                     = "core"
  I4G_API_KEY                      = "dev-analyst-token"
  I4G_VERTEX_SEARCH_PROJECT        = "i4g-dev"
  I4G_VERTEX_SEARCH_LOCATION       = "global"
  I4G_VERTEX_SEARCH_DATA_STORE     = "retrieval-poc"
  I4G_VERTEX_SEARCH_SERVING_CONFIG = "default_search"
}
