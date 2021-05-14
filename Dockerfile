FROM python:3.9.5-alpine3.13

LABEL "com.github.actions.name"="Label approved pull requests"
LABEL "com.github.actions.description"="Add All Approved label pull requests when all reviewers have approved and Needs QA label when all checks have passed"
LABEL "com.github.actions.icon"="tag"
LABEL "com.github.actions.color"="gray-dark"

LABEL version="1.0.0"
LABEL repository="https://github.com/rewardops/label-when-approved-action"
LABEL maintainer="Steve Melo <steve.melo@rewardops.com>"

RUN pip install pygithub

ADD entrypoint.py /entrypoint.py
ENTRYPOINT ["/entrypoint.py"]
