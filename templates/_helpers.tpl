{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "smartcheck.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}


{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "smartcheck.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}


{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "smartcheck.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}


{{/*
Create an image source.
*/}}
{{- define "image.source" -}}
{{- if or (eq (default "" .registry) "-") (eq (default "-" .imageDefaults.registry) "-") -}}
{{- if .digest -}}
{{- printf "%s@%s" .repository .digest | quote -}}
{{- else -}}
{{- printf "%s:%s" .repository .tag | quote -}}
{{- end -}}
{{- else -}}
{{- if .digest -}}
{{- printf "%s/%s@%s" (default .imageDefaults.registry .registry) .repository .digest | quote -}}
{{- else -}}
{{- printf "%s/%s:%s" (default .imageDefaults.registry .registry) .repository .tag | quote -}}
{{- end -}}
{{- end -}}
{{- end -}}


{{/*
Provide network policy for additional outbound ports
*/}}
{{- define "smartcheck.networkpolicy.outbound" -}}
{{ if .Values.networkPolicy.enabled }}
{{- range $port := .Values.networkPolicy.additionalOutboundPorts }}
- to: # any
  ports:
    - protocol: TCP
      port: {{ $port }}
{{- end }}
{{- end }}
{{- end -}}{{/*define*/}}


{{/*
Provide HTTP proxy environment variables
*/}}
{{- define "smartcheck.proxy.env" -}}
- name: HTTP_PROXY
  valueFrom:
    configMapKeyRef:
      name: {{ template "smartcheck.fullname" . }}-outbound-proxy
      key: httpProxy
- name: HTTPS_PROXY
  valueFrom:
    configMapKeyRef:
      name: {{ template "smartcheck.fullname" . }}-outbound-proxy
      key: httpsProxy
- name: NO_PROXY
  valueFrom:
    configMapKeyRef:
      name: {{ template "smartcheck.fullname" . }}-outbound-proxy
      key: noProxy
- name: PROXY_USER
  valueFrom:
    secretKeyRef:
      name: {{ template "smartcheck.fullname" . }}-outbound-proxy-credentials
      key: username
- name: PROXY_PASS
  valueFrom:
    secretKeyRef:
      name: {{ template "smartcheck.fullname" . }}-outbound-proxy-credentials
      key: password
{{- end -}}{{/*define*/}}
