project_id    = "i4g-dev"
fastapi_image = "us-central1-docker.pkg.dev/i4g-dev/applications/fastapi:dev"

fastapi_env_vars = {
  I4G_ENV                  = "dev"
  I4G_STORAGE__SQLITE_PATH = "/tmp/i4g_store.db"
}

fastapi_invoker_member = "allUsers"

streamlit_image = "us-central1-docker.pkg.dev/i4g-dev/applications/streamlit:dev"

streamlit_env_vars = {
  I4G_ENV                = "dev"
  I4G_API__KEY           = "dev-analyst-token"
  STREAMLIT_SERVER_TITLE = "i4g Analyst Dashboard"
}

streamlit_invoker_member = "allUsers"

vertex_search_data_store_id = "retrieval-poc"
vertex_search_display_name  = "Retrieval PoC Data Store"

