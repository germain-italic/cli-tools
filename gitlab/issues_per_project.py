import os
import requests
import logging
import pandas as pd
from dotenv import load_dotenv, find_dotenv

# Set up logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

# Load environment variables from .env file
dotenv_path = find_dotenv("../.env")
if not load_dotenv(dotenv_path):
    logging.error("Could not load .env file.")
else:
    logging.info(".env file loaded successfully.")

GITLAB_URL = os.getenv("GITLAB_URL")
PRIVATE_TOKEN = os.getenv("PRIVATE_TOKEN")

if not GITLAB_URL or not PRIVATE_TOKEN:
    logging.error("GITLAB_URL or PRIVATE_TOKEN not set. Check your .env file.")
else:
    logging.info("GITLAB_URL and PRIVATE_TOKEN loaded successfully.")

# Function to get all projects
def get_all_projects():
    logging.info("Fetching all projects...")
    projects = []
    page = 1
    while True:
        logging.info(f"Fetching page {page} of projects...")
        response = requests.get(f"{GITLAB_URL}/api/v4/projects", headers={"PRIVATE-TOKEN": PRIVATE_TOKEN}, params={"per_page": 100, "page": page})
        if response.status_code != 200:
            logging.error(f"Failed to fetch projects: {response.status_code}")
            break
        projects += response.json()
        if len(response.json()) < 100:
            break
        page += 1
    logging.info(f"Total projects fetched: {len(projects)}")
    return projects

# Function to get the number of issues for a project
def get_issues_count(project_id):
    logging.info(f"Fetching issue count for project ID: {project_id}")
    response = requests.get(f"{GITLAB_URL}/api/v4/projects/{project_id}/issues", headers={"PRIVATE-TOKEN": PRIVATE_TOKEN}, params={"per_page": 1})
    if response.status_code == 200:
        issue_count = int(response.headers['X-Total'])
        logging.info(f"Project ID {project_id} has {issue_count} issues.")
        return issue_count
    logging.error(f"Failed to fetch issues for project ID {project_id}: {response.status_code}")
    return 0

# Main logic to find the project with the most issues and create an Excel file
def create_issues_report():
    projects = get_all_projects()
    if not projects:
        logging.error("No projects found.")
        return

    logging.info("Collecting issues data for all projects...")
    project_data = [(project['id'], project['name'], get_issues_count(project['id'])) for project in projects]

    # Create a DataFrame
    df = pd.DataFrame(project_data, columns=['Project ID', 'Project Name', 'Issues Count'])

    # Sort by Issues Count in descending order
    df = df.sort_values(by='Issues Count', ascending=False)

    # Save to Excel
    output_file = 'gitlab/gitlab_projects_issues_report.xlsx'
    df.to_excel(output_file, index=False)

    logging.info(f"Excel report created: {output_file}")

# Output the project with the most issues and create Excel report
if __name__ == "__main__":
    create_issues_report()
    logging.info("Script execution completed.")
