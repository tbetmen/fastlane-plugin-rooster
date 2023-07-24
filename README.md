# rooster plugin

[![fastlane Plugin Badge](https://rawcdn.githack.com/fastlane/fastlane/master/fastlane/assets/plugin-badge.svg)](https://rubygems.org/gems/fastlane-plugin-rooster)
[![License](https://img.shields.io/badge/license-MIT-green.svg?style=flat)](https://github.com/tbetmen/fastlane-plugin-rooster/blob/main/LICENSE)
[![Gem Version](https://badge.fury.io/rb/fastlane-plugin-rooster.svg)](https://rubygems.org/gems/fastlane-plugin-rooster)

## Getting Started

This project is a [_fastlane_](https://github.com/fastlane/fastlane) plugin. To get started with `fastlane-plugin-rooster`, add it to your project by running:

```bash
fastlane add_plugin rooster
```

## About Rooster

Rooster is fastlane action to send Gitlab merge request to Slack using webhook, for now only has one action `rooster_merge_request`.

## Example

Check out the [example `Fastfile`](fastlane/Fastfile) to see how to use `rooster_merge_request` action. Try it by cloning the repo, running `fastlane install_plugins` and `bundle exec fastlane test_env`.

There are also some example files that used in `rooster_merge_request` action:
1. Sample uses `.env` in [example `.env.example`](example/.env.example) for setting all action parameters or just private variable like Gitlab Api Token. 
2. [example `slack_message_format.json`](example/slack_message_format.json) used for slack message format to replace default value given in action.
3. [example `slack_users.csv`](example/slack_users.csv) slack users and gitlab users mapping format.

Slack message preview has opened merge request

![has merge request](./screenshots/sample%20merge%20request.png)

Slack message preview merge request empty

![has merge request](./screenshots/sample%20merge%20request%20empty.png)

## Parameters

The action parameters `gitlab_token` and others can also be omitted when their values are [set as environment variables](https://docs.fastlane.tools/advanced/#environment-variables).

Here is the list of all existing parameters for `rooster_merge_request` action:

| Key | Env Var               | Default                                                                       | Optional | Description                                                                                               |
|-----|-----------------------|-------------------------------------------------------------------------------|----------|-----------------------------------------------------------------------------------------------------------|
| `gitlab_token` | `ROOSTER_GITLAB_ACCESS_TOKEN` | -                                                                             | false    | API Token for Gitlab [find out here](https://docs.gitlab.com/ee/user/profile/personal_access_tokens.html) |
| `gitlab_project_id` | `ROOSTER_GITLAB_PROJECT_ID` | -                                                                             | false    | Gitlab project id, you can find in Project Overview menu located below project name.                                                                                                                                                                  |
| `slack_webhook_url` | `ROOSTER_SLACK_WEBHOOK_URL` | -                                                                             | false    | Slack webhook url, check this link for more detail [Slack Webhooks](https://api.slack.com/messaging/webhooks)                                                                                                                                         |
| `gitlab_milestones_path` | `ROOSTER_GITLAB_MILESTONES_PATH` | -                                                                             | true     | Gitlab group or project milestones with given format either `groups/:group_id` or `projects/:project_id`. You can find `group id` similar with project id in Group Overview. [Gitlab Milestones](https://docs.gitlab.com/ee/user/project/milestones/) |
| `gitlab_merge_request_total` | `ROOSTER_GITLAB_MERGE_REQUEST_TOTAL` | 10                                                                            | true     | Maximum merge request when fetching data from gitlab, uses in query param `per_page`                      |
| `slack_users_file` | `ROOSTER_SLACK_USERS_FILE` | -                                                                             | true     | Comma separate file that contains mapping user of gitlab and slack using id                               |
| `slack_message_format_file` | `ROOSTER_SLACK_MESSAGE_FORMAT_FILE` | Check in this [file](lib/fastlane/plugin/rooster/helper/slack_file_client.rb) | true     | Slack message format in json format contains `text`, `header`, `mr_item`, `footer`, and `empty_mr_text`.  |
| `gitlab_merge_request_milestone` | `ROOSTER_GITLAB_MERGE_REQUEST_MILESTONE` | '' | true     | Milestone will be used in merge request parameter as query param.  |

## Replace word in `slack_message_format`

In slack message format json has word replacement, check this table to see all possibility:

| Key | Availability | Description                                     |
|-----|--------------|-------------------------------------------------|
| `MR_TOTAL`  | header       | Total merge request to be shown in slack        |
| `MR_MILESTONE`  | header, empty_mr_text     | Current active milestone                        |
| `MR_TITLE`  | mr_item             | Title of merge request                          |
| `MR_TIME`  | mr_item             | Time relative to current date like `3 days ago` |
| `MR_ASSIGNEE_SINGLE`  | mr_item             | Merge request assignee just one user            |
| `MR_ASSIGNEES`  | mr_item             | All assignee users in merge request             |
| `MR_REVIEWERS`  | mr_item             | All reviewer users in merge request             |
| `MR_LABELS`  | mr_item             | Merge request labels                            |
| `MR_LINK`  | mr_item             | Merge request link                              |

### Example usage

before
```json
{
    "text": "Hello, its beautiful day!",
    "header": "Hi there, Just wanted to let you know that we have MR_TOTAL merge requests that need your attention.",
    "mr_item": "<MR_LINK|MR_TITLE> MR_ASSIGNEE_SINGLE",
    "footer": "Thank you",
    "empty_mr_text": "Congratulation there is no merge request anymore, keep the good works"
}
```
after
```json
{
    "text": "Hello, its beautiful day!",
    "header": "Hi there, Just wanted to let you know that we have 10 merge requests that need your attention.",
    "mr_item": "<https://gitlab.com/nnn/merge_requests/1|feat: Add new feature mobile prepaid> @Bruce Wayne",
    "footer": "Thank you",
    "empty_mr_text": "Congratulation there is no merge request anymore, keep the good works"
}
```

## Run tests for this plugin

To run both the tests, and code style validation, run

```
rake
```

To automatically fix many of the styling issues, use
```
rubocop -a
```

## Issues and Feedback

For any other issues and feedback about this plugin, please submit new [Github Issue](https://github.com/tbetmen/fastlane-plugin-rooster/issues).

## Troubleshooting

If you have trouble using plugins, check out the [Plugins Troubleshooting](https://docs.fastlane.tools/plugins/plugins-troubleshooting/) guide.

## Using _fastlane_ Plugins

For more information about how the `fastlane` plugin system works, check out the [Plugins documentation](https://docs.fastlane.tools/plugins/create-plugin/).

## About _fastlane_

_fastlane_ is the easiest way to automate beta deployments and releases for your iOS and Android apps. To learn more, check out [fastlane.tools](https://fastlane.tools).
