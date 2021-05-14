#!/usr/bin/env python

import os
from github import Github

for k, v in sorted(os.environ.items()):
    print(k+':', v)
print('\n')
# list elements in path environment variable
[print(item) for item in os.environ['PATH'].split(';')]
quit()


notset = ''
usernames_involved = set()
d = {}
lbl = []
gh_ref = int(os.environ.get('GITHUB_REF').split('/')[2])

if os.environ.get('GITHUB_TOKEN') != None:
  gh_token = os.environ.get('GITHUB_TOKEN')
else:
  print("GITHUB_TOKEN not set")
  notset = True

if os.environ.get('GITHUB_EVENT_PATH') != None:
  gh_event_path = os.environ.get('GITHUB_EVENT_PATH')
else:
  print("GITHUB_EVENT_PATH not set")
  notset = True

if os.environ.get('GITHUB_REPOSITORY') != None:
  gh_repo = os.environ.get('GITHUB_REPOSITORY')
else:
  print("GITHUB_REPOSITORY not set")
  notset = True

if os.environ.get('GITHUB_REPOSITORY_OWNER') != None:
  gh_owner = os.environ.get('GITHUB_REPOSITORY_OWNER')
else:
  print("GITHUB_REPOSITORY_OWNER not set")
  notset = True

if notset == True:
  print("Environment not set. good-bye!")
  quit()

repo_path = gh_owner + "/" + gh_repo
g = Github(gh_token)

repo = g.get_repo(repo_path)
pr = repo.get_pull(gh_ref)
labels = pr.labels

print('REPO: {}\nPR Number: {}\nPR Title: {}\n' .format(repo_path, pr.number, pr.title))

print('Reviews:')
for review in pr.get_reviews():
  usernames_involved.add(review.user.login)
  print('User: {}, Review ID: {}, Status: {}' .format(review.user.login, review.id, pr.get_review(review.id).state))

users_requested, teams_requested = pr.get_review_requests()

for l in labels:
  lbl.append(l.name)

for user in users_requested:
  usernames_involved.add(user.login)

for team in teams_requested:
  for user in team.get_members():
    usernames_involved.add(user.login)

for approver in usernames_involved:
  for review in pr.get_reviews():
    if pr.get_review(review.id).state == "APPROVED":
      d[review.user.login] = pr.get_review(review.id).state

approvals = len(d)
review_requests = len(pr.get_review_requests())

print('\nNeed {} approvers. Got {}' .format(review_requests, approvals))
if approvals == review_requests:
  if 'Approved by all' not in lbl:
    print("Adding label 'Approved by all'")
    pr.add_to_labels('Approved by all')
  else:
    print("'Approved by all' label already set, not adding")
else:
  if 'Approved by all' in lbl:
    print("Removing label 'Approved by all'")
    pr.remove_from_labels('Approved by all')
  else:
    print("'Approved by all' not set, not removed")

# Check all tests have passed
c = pr.get_commits()[pr.commits -1]
br = g.get_repo(repo_path).get_commit(c.sha)

if br.get_combined_status().state == "success":
  print("All checks have passed")
  if 'Needs QA' not in lbl:  
    print("Adding label 'Needs QA'")
    pr.add_to_lables('Needs QA')
  else:
    print("'Needs Qa' label already set, not adding")
else:
  print("Some checks have not passed")
  if 'Needs QA' in lbl:
    print("Removing label 'Needs QA'")
    pr.remove_from_labels('Needs QA')
  else:
    print("'Needs QA' not set, not removed")
