[issues_per_project.py] : Count the number of issues per projects on a self-hosted Gitlab instance, and outputs the result in a sorted Excel spreadsheet

**Disclaimer:** tested ONLY on self-hosted Gitlab instance!

1. Install the requests, python-dotenv, and pandas libraries:
`pip install requests python-dotenv pandas openpyxl`

2. Duplicate the [../.env.dist](.env.dist) file one level above this script directory, rename the copy `.env`, enter your Gitlab API connexion details
- To create your access token, go to https://your-gitlab-instance.com/-/user_settings/personal_access_tokens
- Create a new token with the `api` scope

3. Run `python gitlab/issues_per_project.py`
