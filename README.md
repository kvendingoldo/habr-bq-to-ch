# habr-bq-to-ch

## Export data from BigQuery to Yandex S3
```shell
export GOOGLE_APPLICATION_CREDENTIALS="<path_to_json>"
export BOTO_CONFIG="./credentials.boto"
python3 00_migrate.py \
    --bq_project=<bq_project_id> \
    --bq_location=<bq_location> \
    --gs_bucket=<gcp_bucket> \
    --yc_bucket=<yc_bucket>
```

## Import data from Yandex S3 to ClickHouse

```shell
export GOOGLE_APPLICATION_CREDENTIALS="<path_to_json>"
export BOTO_CONFIG="./credentials.boto"
python3 01_import.py \
    --s3_bucket_name="<yc_bucket_name>" \
    --s3_access_key='<yc_bucket_access_key>' \
    --s3_secret_key='<yc_bucket_secret_key>' \
    --ch_cluster_id='<clickhouse_cluster_id>' \
    --ch_host='clickhouse_cluster_host' \
    --ch_password='<clickhouse_cluster_password>' \
    --ch_database='clickhouse_database' \
    --bq_table_pattern='<tables_prefix_to_import>' \
    --bq_project_id="<bq_project_id>" \
    --bq_database="<bq_database>"
```
