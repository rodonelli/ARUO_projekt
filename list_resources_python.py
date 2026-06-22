import argparse
import csv
import json
from pathlib import Path

from azure.identity import DefaultAzureCredential
from azure.mgmt.resource import ResourceManagementClient


def main() -> None:
    parser = argparse.ArgumentParser(description="List Azure resources with Python SDK.")
    parser.add_argument("--subscription-id", required=True, help="Azure subscription ID")
    parser.add_argument("--resource-group", default="rg-cloud-project", help="Azure resource group name")
    parser.add_argument("--output-directory", default="evidence", help="Directory for output files")
    args = parser.parse_args()

    output_directory = Path(args.output_directory)
    output_directory.mkdir(parents=True, exist_ok=True)

    credential = DefaultAzureCredential()
    client = ResourceManagementClient(credential, args.subscription_id)

    resources = []
    for resource in client.resources.list_by_resource_group(args.resource_group):
        resources.append(
            {
                "name": resource.name,
                "type": resource.type,
                "location": resource.location,
                "resource_group": args.resource_group,
                "id": resource.id,
            }
        )

    json_path = output_directory / "resources-python.json"
    csv_path = output_directory / "resources-python.csv"

    json_path.write_text(json.dumps(resources, indent=2), encoding="utf-8")

    with csv_path.open("w", newline="", encoding="utf-8") as csv_file:
        writer = csv.DictWriter(
            csv_file,
            fieldnames=["name", "type", "location", "resource_group", "id"],
        )
        writer.writeheader()
        writer.writerows(resources)

    print(f"Saved {len(resources)} resources to:")
    print(f"  {json_path}")
    print(f"  {csv_path}")


if __name__ == "__main__":
    main()
