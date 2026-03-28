project_id       = "i4g-ml"
region           = "us-central1"
data_bucket_name = "i4g-ml-data"

# Champion model (latest XGBoost)
model_artifact_uri = "gs://i4g-ml-data/models/classification-xgboost-v1-20260326-1737"

# Shadow mode — PyTorch model for A/B comparison (P2-B)
shadow_model_artifact_uri = "gs://i4g-ml-data/models/classification-opt125m-v1-merged"

# Champion/Challenger A/B routing (Sprint 1)
challenger_model_artifact_uri = "gs://i4g-ml-data/models/classification-opt125m-v1-merged"
challenger_traffic_weight     = "0.2"

# Risk scoring model (Sprint 4)
risk_model_artifact_uri = "gs://i4g-ml-data/models/risk-scoring-xgboost-v1-20260328-0447"

# NER model (P2-A)
ner_model_artifact_uri = "gs://i4g-ml-data/models/ner-bert-v1-r9"

# Cost-aware routing (Sprint 6) — enable after verifying A/B routing works
cost_aware_routing = "true"

# Document similarity (Sprint 5)
similarity_enabled = "true"
