#!/usr/bin/env bash
#
helm repo add openebs https://openebs.github.io/charts
yq -i ".version = \"${1}\" | .appVersion style=\"double\" | .appVersion = \"${1}\"" chart/Chart.yaml
helm dependency build chart
helm package chart