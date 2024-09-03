import boto3
import clickhouse_connect
import argparse
from google.cloud import bigquery
import logging

from lib import convert_bq_to_ch_schema


def list_s3_files(s3_client, bucket_name, file_pattern):
    """List files in S3 bucket that match the given pattern."""
    response = s3_client.list_objects_v2(
        Bucket=bucket_name, Prefix=file_pattern)
    files = [content['Key'] for content in response.get('Contents', [])]
    return files


def clickhouse_import(ch_client, ch_cluster_id, s3_bucket_name, s3_obj_name, ch_data_fields):
    table_name = s3_obj_name.rsplit('-', 1)[0]

    insert_query = f"""
    INSERT INTO {table_name}
    SELECT *
    FROM s3Cluster(
        '{ch_cluster_id}',
        'https://storage.yandexcloud.net/{s3_bucket_name}/{s3_obj_name}',
        'Parquet',
        {ch_data_fields}
    );
    """
    logging.debug(f"Insert query: {insert_query}")
    try:
        ch_client.command(insert_query)
    except Exception as ex:
        logging.error(f"Exception for query: {insert_query}: ex")
    logging.info(f"Data has migrated to {table_name}")


def bq_schema_to_dict(fields):
    schema_list = []
    for field in fields:
        field_dict = {
            "name": field.name,
            "type": field.field_type,
            "mode": field.mode
        }
        if field.fields:  # Check if the field has nested fields
            field_dict["fields"] = bq_schema_to_dict(field.fields)
        schema_list.append(field_dict)
    return schema_list


def parse_args():
    parser = argparse.ArgumentParser(description='')
    parser.add_argument('--s3_bucket_name', type=str,
                        help='Name of YC bucket with migrated data')
    parser.add_argument('--s3_access_key', type=str,
                        help='YC bucket access key')
    parser.add_argument('--s3_secret_key', type=str,
                        help='YC bucket secret key')
    parser.add_argument('--s3_region', type=str,
                        help='YC bucket region', default='ru-central1-a')
    parser.add_argument('--ch_cluster_id', type=str,
                        help='YC ClickHouse cluster ID')
    parser.add_argument('--ch_host', type=str,
                        help='YC ClickHouse cluster host')
    parser.add_argument('--ch_port', type=str,
                        help='YC ClickHouse port', default=8123)
    parser.add_argument('--ch_user', type=str,
                        help='YC ClickHouse user', default='admin')
    parser.add_argument('--ch_password', type=str,
                        help='YC ClickHouse password')
    parser.add_argument('--ch_database', type=str,
                        help='YC ClickHouse database name')
    parser.add_argument('--bq_database', type=str, help='BQ database name')
    parser.add_argument('--bq_project_id', type=str, help='BQ project ID')
    parser.add_argument('--bq_table_pattern', type=str,
                        help='BQ table pattern to import', default='')

    return parser.parse_args()


def main():
    args = parse_args()
    logging.basicConfig(level=logging.INFO)

    s3_client = boto3.client(
        's3',
        region_name=args.s3_region,
        endpoint_url='https://storage.yandexcloud.net',
        aws_access_key_id=args.s3_access_key,
        aws_secret_access_key=args.s3_secret_key
    )

    ch_client = clickhouse_connect.get_client(
        host=args.ch_host,
        port=args.ch_port,
        user=args.ch_user,
        password=args.ch_password,
        database=args.ch_database,
        secure=False,
        verify=False,
        connect_timeout=60
    )

    bq_client = bigquery.Client()

    bq_project_id = args.bq_project_id
    bq_database = args.bq_database
    s3_bucket_name = args.s3_bucket_name

    bq_tables = bq_client.list_tables(bq_database)
    if bq_tables:
        for table in bq_tables:
            table_id = table.table_id
            if args.bq_table_pattern in table_id or args.bq_table_pattern == "":
                table = bq_client.get_table(
                    f"{bq_project_id}.{bq_database}.{table_id}")
                table_schema = {"fields": bq_schema_to_dict(table.schema)}

                create_table_query, ch_data_fields = convert_bq_to_ch_schema.convert_bq_to_ch_schema(
                    table_name=table_id,
                    bq_schema_json=table_schema
                )
                try:
                    if ch_client.command(f"CHECK TABLE {table_id}") == 1:
                        ch_client.command(f"DROP TABLE {table_id}")
                        logging.info(f"Table {table_id} has been dropped")
                except Exception as ex:
                    logging.error(ex)

                try:
                    ch_client.command(create_table_query)
                    logging.info(f"Table {table_id} has been created")
                except Exception as ex:
                    logging.error(ex)

                s3_objs = list_s3_files(s3_client, s3_bucket_name, table_id)
                for s3_obj_name in s3_objs:
                    clickhouse_import(
                        ch_client=ch_client,
                        ch_cluster_id=args.ch_cluster_id,
                        s3_bucket_name=s3_bucket_name,
                        s3_obj_name=s3_obj_name,
                        ch_data_fields=ch_data_fields
                    )
        return

    else:
        logging.error(f"Dataset {bq_database} does not contain any tables.")


if __name__ == "__main__":
    main()
