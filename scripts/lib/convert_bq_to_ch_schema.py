bq_to_ch_type_map = {
    "STRING": "Nullable(String)",
    "BYTES": "Nullable(String)",
    "INTEGER": "Nullable(Int64)",
    "INT64": "Nullable(Int64)",
    "FLOAT": "Nullable(Float64)",
    "FLOAT64": "Nullable(Float64)",
    "BOOLEAN": "Nullable(UInt8)",
    "BOOL": "Nullable(UInt8)",
    "TIMESTAMP": "Nullable(DateTime)",
    "DATE": "Nullable(Date)",
    "TIME": "Nullable(String)",  # ClickHouse has no direct Time type, you can use String or DateTime
    "DATETIME": "Nullable(DateTime)",
    "GEOGRAPHY": "Nullable(String)",  # ClickHouse has no direct Geography type, you might want to store it as a String
    "NUMERIC": "Nullable(Decimal(38,9))",  # ClickHouse supports decimals, but you need to specify precision and scale
    "BIGNUMERIC": "Nullable(Decimal(76,38))",  # Adjust precision and scale if needed
    "RECORD": "Tuple",  # Nested structures are converted to Tuple in ClickHouse
    "STRUCT": "Tuple",  # Same as RECORD
    "ARRAY": "Array",  # Arrays need to be handled carefully
}


def convert_bq_field_to_ch(field):
    """
    Recursively convert a BigQuery field to a ClickHouse column definition, handling nested fields with Tuple.
    """

    bq_type = field['type'].upper()
    # Get the mode, if not specified assume it's not repeated
    mode = field.get('mode', '').upper()

    if bq_type == "RECORD" or bq_type == "STRUCT":
        # Convert nested fields to a Tuple
        nested_fields = []
        for nested_field in field['fields']:
            nested_field_type = convert_bq_field_to_ch(nested_field)
            nested_fields.append(nested_field_type)
        ch_type = f"Tuple({', '.join(nested_fields)})"

    elif bq_type == "ARRAY":
        # Handle arrays, checking if the array contains a RECORD/STRUCT or simple types
        sub_field = field['fields'][0] if 'fields' in field else None
        if sub_field:
            sub_type = convert_bq_field_to_ch(sub_field)
            ch_type = f"Array({sub_type.split(' ')[1]})"
        else:
            ch_type = "Array(String)"

    else:
        # Handle primitive types
        ch_type = bq_to_ch_type_map.get(bq_type, "String")

    if mode == "REPEATED":
        ch_type = f"Array({ch_type})"
    return f"`{field['name']}` {ch_type}"


def convert_bq_to_ch_schema(table_name, bq_schema_json):
    ch_columns = []
    for field in bq_schema_json['fields']:
        ch_columns.append(convert_bq_field_to_ch(field))

    create_table_query = f"CREATE TABLE {table_name} (\n    " + ",\n    ".join(
        ch_columns) + "\n) ENGINE = MergeTree() ORDER BY tuple();"

    data_fields = "\n    " + ",\n    ".join(ch_columns) + "\n"
    data_fields = f"`{data_fields.replace('`', '')}`"

    return create_table_query, data_fields
