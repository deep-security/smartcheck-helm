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

{{/* Image and pull policy */}}
{{- define "image" -}}
{{- $project := (default (default "deepsecurity" .defaults.project) .image.project) }}
{{- $repository := printf "%s/%s" $project (required ".repository is required!" .image.repository) }}
{{- $tag := (default .defaults.tag .image.tag) }}
image: {{ include "image.source" (dict "repository" $repository "registry" .image.registry "tag" $tag "imageDefaults" .defaults "digest" .image.digest) }}
imagePullPolicy: {{ default (default "Always" .defaults.pullPolicy) .image.pullPolicy }}
{{- end -}}{{/* define image*/}}

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
- name: _PROXY_CONFIG_CHECKSUM
  value: {{ include (print $.Template.BasePath "/outbound-proxy.yaml") . | sha256sum }}
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


{{- define "smartcheck.to-internal-service-networkpolicy" -}}
- to:
    {{- $release := .Release.Name -}}
    {{- $heritage := .Release.Service -}}
    {{- $extraLabels := default (dict) .Values.extraLabels -}}
    {{ range default (list) .services }}
    - podSelector:
        matchLabels:
          service: {{ . }}
          release: {{ $release }}
          heritage: {{ $heritage }}
          {{- range $k, $v := $extraLabels }}
          {{ $k }}: {{ quote $v }}
          {{- end }}{{/* range $extraLabels */}}
    {{- end -}}{{/* range .services */}}
  ports:
    - protocol: TCP
      port: 8081
{{- end -}}{{/* define */}}


{{- define "smartcheck.to-dns-networkpolicy" -}}
- to: # any
  ports:
    - protocol: TCP
      port: 53
    - protocol: UDP
      port: 53
{{- end -}}{{/* define */}}


{{- define "smartcheck.to-db-networkpolicy" -}}
{{- if not .Values.db.host }}
- to:
    - podSelector:
        matchLabels:
          service: db
          release: {{ .Release.Name }}
          heritage: {{ .Release.Service }}
          {{- range $k, $v := (default (dict) .Values.extraLabels) }}
          {{ $k }}: {{ quote $v }}
          {{- end }}{{/* .Values.extraLabels **/}}
  ports:
    - protocol: TCP
      port: {{ default 5432 .Values.db.port }}
{{- else }}{{/* Values.db.host */}}
- to: # any
  ports:
    - protocol: TCP
      port: {{ default 5432 .Values.db.port }}
{{- end -}}{{/* Values.db.host */}}
{{- end -}}{{/* define */}}


{{/*
Create a database secret for a service

Example:
  include "smartcheck.service.database.secret" (dict "Chart" .Chart "Values" .Values "Release" .Release "service" "auth")

=> a Secret with keys `database-user`, `database-password`, and `database-secret`

The database user and password will be derived from .Values.auth.secretSeed and the provided service name.
The database secret will be derived from .Values.auth.secretSeed and the release name unless .Values.db.secret is provided, in which case that value will be used.
*/}}
{{- define "smartcheck.service.database.secret" -}}
apiVersion: v1
kind: Secret
metadata:
  name: {{ template "smartcheck.fullname" . }}-{{ .service }}-db
  labels:
    app: {{ template "smartcheck.name" . }}
    release: "{{ .Release.Name }}"
    heritage: "{{ .Release.Service }}"
{{- range $k, $v := (default (dict) .Values.extraLabels) }}
    {{ $k }}: {{ quote $v }}
{{- end }}
type: Opaque
data:
  database-user: {{ derivePassword 1 "maximum" (toString (required "You must provide a value for auth.secretSeed. Use --set auth.secretSeed={password} or include a value in your overrides.yaml file." (default .Values.auth.masterPassword .Values.auth.secretSeed))) (join "-" (list .service "db-user")) .Release.Name | toString | b64enc | quote }}
  database-password: {{ derivePassword 1 "maximum" (toString (default .Values.auth.masterPassword .Values.auth.secretSeed)) (join "-" (list .service "db-password" "2")) .Release.Name | toString | b64enc | quote }}
  {{ if .Values.db.secret -}}
  database-secret: {{ .Values.db.secret | toString | b64enc | quote }}
  {{ else -}}
  database-secret: {{ derivePassword 1 "maximum" (toString (default .Values.auth.masterPassword .Values.auth.secretSeed)) "db-secret" .Release.Name | toString | b64enc | quote }}
  {{- end }}
{{- end -}}{{/*define*/}}


{{/*
Provide database environment variables for a service.
*/}}
{{- define "smartcheck.service.database.env" -}}
- name: PGDATABASE
  value: {{ join "" (list .service "db") }}
- name: PGHOST
  value: {{ default "db" .Values.db.host | quote }}
- name: PGPORT
  value: {{ default "5432" .Values.db.port | quote }}
- name: PGSSLMODE
  value: {{ if .Values.db.host }}{{ default "" .Values.db.tls.mode | quote }}{{ else }}disable{{ end }}
{{- if hasKey (default (dict) .Values.db) "tls" -}}
{{- if hasKey (default (dict) .Values.db.tls) "ca" }}
{{- if hasKey .Values.db.tls.ca "valueFrom" -}}
{{- if or (ne "" (default "" .Values.db.tls.ca.valueFrom.secretKeyRef.name)) (ne "" (default "" .Values.db.tls.ca.valueFrom.configMapKeyRef.name)) }}
- name: PGSSLROOTCERT
  value: /trust/db/ca.pem
{{- end -}}{{/* if secretKeyRef.name || configMapKeyRef.name */}}
{{- end -}}{{/* if hasKey .Values.db.tls.ca.valueFrom */}}
{{- end }}{{/* if hasKey .Values.db.tls "ca" */}}
{{- end }}{{/* if hasKey .Values.db "tls" */}}
- name: _DB_CREDENTIALS_SECRET_CHECKSUM
  value: {{ include "smartcheck.service.database.secret" (dict "Chart" .Chart "Values" .Values "Release" .Release "service" .service) | sha256sum }}
- name: PGUSER
  valueFrom:
    secretKeyRef:
      name: {{ template "smartcheck.fullname" . }}-{{ .service }}-db
      key: database-user
- name: PGPASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ template "smartcheck.fullname" . }}-{{ .service }}-db
      key: database-password
- name: PGCONNECT_TIMEOUT
  value: "5"
- name: DB_SECRET
  valueFrom:
    secretKeyRef:
      name: {{ template "smartcheck.fullname" . }}-{{ .service }}-db
      key: database-secret
{{- end }}{{/*define*/}}

{{- define "smartcheck.activation-code.env" -}}
- name: _ACTIVATION_CODE_SECRET_CHECKSUM
  value: {{ include (print $.Template.BasePath "/activation-code.yaml") . | sha256sum }}
- name: ACTIVATION_CODE
  valueFrom:
    secretKeyRef:
      name: {{ template "smartcheck.fullname" . }}-activation-code
      key: code
{{- end -}}{{/*define */}}

{{- define "smartcheck.db-trust-volume" -}}
{{- if hasKey (default (dict) .Values.db) "tls" -}}
{{- if hasKey .Values.db.tls "ca" -}}
{{- if hasKey .Values.db.tls.ca "valueFrom" -}}
{{- if or (ne "" (default "" .Values.db.tls.ca.valueFrom.secretKeyRef.name)) (ne "" (default "" .Values.db.tls.ca.valueFrom.configMapKeyRef.name)) -}}
- name: database-ca
  {{- if .Values.db.tls.ca.valueFrom.secretKeyRef.name }}
  secret:
    secretName: {{ .Values.db.tls.ca.valueFrom.secretKeyRef.name }}
    items:
    - key: {{ required ".key is required!" .Values.db.tls.ca.valueFrom.secretKeyRef.key }}
      path: ca.pem
  {{- else if .Values.db.tls.ca.valueFrom.configMapKeyRef.name }}
  configMap:
    name: {{ .Values.db.tls.ca.valueFrom.configMapKeyRef.name }}
    items:
    - key: {{ required ".key is required!" .Values.db.tls.ca.valueFrom.configMapKeyRef.key }}
      path: ca.pem
  {{- end -}}{{/* else if .Values.db.tls.ca.valueFrom.configMapKeyRef.name */}}
{{- end -}}{{/* if secretKeyRef.name || configMapKeyRef.name */}}
{{- end -}}{{/* if hasKey .Values.db.tls.ca "valueFrom" */}}
{{- end -}}{{/* if hasKey .Values.db.tls "ca" */}}
{{- end -}}{{/* if hasKey .Values.db "tls" */}}
{{- end -}}

{{- define "smartcheck.db-trust-volume-mount" -}}
{{- if hasKey (default (dict) .Values.db) "tls" -}}
{{- if hasKey .Values.db.tls "ca" -}}
{{- if hasKey .Values.db.tls.ca "valueFrom" -}}
{{- if or (ne "" (default "" .Values.db.tls.ca.valueFrom.secretKeyRef.name)) (ne "" (default "" .Values.db.tls.ca.valueFrom.configMapKeyRef.name)) -}}
- name: database-ca
  mountPath: /trust/db
  readOnly: true
{{- end -}}{{/* if secretKeyRef.name || configMapKeyRef.name */}}
{{- end -}}{{/* if hasKey .Values.db.tls.ca "valueFrom" */}}
{{- end -}}{{/* if hasKey .Values.db.tls "ca" */}}
{{- end -}}{{/* if hasKey .Values.db "tls" */}}
{{- end -}}


{{/*
DB init container
*/}}
{{- define "smartcheck.db-initcontainer" -}}
name: db-init
{{- if .Values.securityContext.enabled }}
{{- $securityContext := default .Values.securityContext.default (index .Values.securityContext .service) }}
{{- $initDBContainerSecurityContext := default .Values.securityContext.default.container $securityContext.initDBContainer }}
securityContext: {{- toYaml $initDBContainerSecurityContext | nindent 4 }}
{{- end }}{{/* if .Values.securityContext.enabled */}}
{{- $imageDefaults := .Values.images.defaults }}
{{- with .Values.images.dbInitializer -}}
{{- $project := (default (default "deepsecurity" $imageDefaults.project) .project) }}
{{- $repository := printf "%s/%s" $project (required ".repository is required!" .repository) }}
{{- $tag := (default $imageDefaults.tag .tag) }}
image: {{ include "image.source" (dict "repository" $repository "registry" .registry "tag" $tag "imageDefaults" $imageDefaults "digest" .digest) }}
imagePullPolicy: {{ default (default "Always" $imageDefaults.pullPolicy) .pullPolicy }}
{{- end }}{{/* with .Values.images.dbInitializer */}}
args:
  - postgres
  - --service-username=$(SERVICE_USER)
  - --service-password=$(SERVICE_PASS)
  - --service-database=$(SERVICE_DB)
{{- $volumeMounts := include "smartcheck.db-trust-volume-mount" . | nindent 2 }}
{{- if (trim $volumeMounts) }}
volumeMounts:
  {{- $volumeMounts }}
{{- end }}{{/* if $volumeMounts */}}
env:
  - name: PGHOST
    value: {{ default "db" .Values.db.host | quote }}
  - name: PGPORT
    value: {{ default "5432" .Values.db.port | quote }}
  - name: PGSSLMODE
    value: {{ if .Values.db.host }}{{ default "" .Values.db.tls.mode | quote }}{{ else }}disable{{ end }}
  {{- if hasKey (default (dict) .Values.db) "tls" -}}
  {{- if hasKey (default (dict) .Values.db.tls) "ca" }}
  {{- if hasKey .Values.db.tls.ca "valueFrom" -}}
  {{- if or (ne "" (default "" .Values.db.tls.ca.valueFrom.secretKeyRef.name)) (ne "" (default "" .Values.db.tls.ca.valueFrom.configMapKeyRef.name)) }}
  - name: PGSSLROOTCERT
    value: /trust/db/ca.pem
  {{- end -}}{{/* if secretKeyRef.name || configMapKeyRef.name */}}
  {{- end -}}{{/* if hasKey .Values.db.tls.ca.valueFrom */}}
  {{- end }}{{/* if hasKey .Values.db.tls "ca" */}}
  {{- end }}{{/* if hasKey .Values.db "tls" */}}
  - name: PGUSER
    valueFrom:
      secretKeyRef:
        key: database-user
        name: {{ template "smartcheck.fullname" . }}-db
  - name: PGPASSWORD
    valueFrom:
      secretKeyRef:
        key: database-password
        name: {{ template "smartcheck.fullname" . }}-db
  - name: PGCONNECT_TIMEOUT
    value: "5"
  - name: SERVICE_DB
    value: {{ .service }}db
  - name: SERVICE_USER
    valueFrom:
      secretKeyRef:
        key: database-user
        name: {{ template "smartcheck.fullname" . }}-{{ .service }}-db
  - name: SERVICE_PASS
    valueFrom:
      secretKeyRef:
        key: database-password
        name: {{ template "smartcheck.fullname" . }}-{{ .service }}-db
resources: {{ toYaml (default .Values.resources.defaults .Values.resources.dbInit) | nindent 2 }}
{{- end -}}{{/* define */}}


{{/*
Vulnerability DB init container
*/}}
{{- define "smartcheck.vulndb-initcontainer" -}}
name: {{ .service }}-db-init
{{- if .Values.securityContext.enabled }}
{{- $securityContext := default .Values.securityContext.default (index .Values.securityContext .service) }}
{{- $initVulnDBContainerSecurityContext := default .Values.securityContext.default.container $securityContext.initVulnDBContainer }}
securityContext: {{- toYaml $initVulnDBContainerSecurityContext | nindent 4 }}
{{- end }}{{/* if .Values.securityContext.enabled */}}
{{- $imageDefaults := .Values.images.defaults }}
{{- with .Values.images.vulnDBInitializer -}}
{{- $project := (default (default "deepsecurity" $imageDefaults.project) .project) }}
{{- $repository := printf "%s/%s" $project (required ".repository is required!" .repository) }}
{{- $tag := (default $imageDefaults.tag .tag) }}
image: {{ include "image.source" (dict "repository" $repository "registry" .registry "tag" $tag "imageDefaults" $imageDefaults "digest" .digest) }}
imagePullPolicy: {{ default (default "Always" $imageDefaults.pullPolicy) .pullPolicy }}
{{- end }}{{/* with .Values.images.vulnDBInitializer */}}
{{- $volumeMounts := include "smartcheck.db-trust-volume-mount" . | nindent 2 }}
{{- if (trim $volumeMounts) }}
volumeMounts:
  {{- $volumeMounts }}
{{- end }}{{/* if $volumeMounts */}}
env:
  {{- include "smartcheck.service.database.env" (dict "Chart" .Chart "Release" .Release "Values" .Values "service" .service) | nindent 2 }}
resources: {{ toYaml (default .Values.resources.defaults .Values.resources.vulnDBInit) | nindent 2 }}
{{- end -}}{{/* define */}}

{{/*
Service account name
*/}}
{{- define "smartcheck.service.account.name" -}}
{{- if (index (index .Values.serviceAccount .role) "annotations") -}}
{{ template "smartcheck.fullname" . }}-{{ lower .role }}
{{- else -}}
default
{{- end -}}{{/* if */}}
{{- end -}}{{/* define */}}

{{/*
Create a service account for a service

Example:
  include "smartcheck.service.account" (dict "Chart" .Chart "Values" .Values "Release" .Release "role" "registryRead" "annotations" $annotationsMap)
*/}}

{{- define "smartcheck.service.account" -}}
apiVersion: v1
kind: ServiceAccount
metadata:
  name: {{ include "smartcheck.service.account.name" (dict "Chart" .Chart "Values" .Values "Release" .Release "role" .role) }}
  annotations:
{{- range $key, $value := .annotations }}
    {{ $key }}: {{ $value | quote }}
{{- end }}
{{- end -}}{{/* define */}}

{{- define "smartcheck.auth.initial-user.secret" -}}
apiVersion: v1
kind: Secret
metadata:
  name:  {{ template "smartcheck.fullname" . }}-auth
  labels:
    app: {{ template "smartcheck.name" . }}
    release: "{{ .Release.Name }}"
    heritage: "{{ .Release.Service }}"
{{- range $k, $v := (default (dict) .Values.extraLabels) }}
    {{ $k }}: {{ quote $v }}
{{- end }}
type: Opaque
data:
  userName: {{ default "administrator" .Values.auth.userName | toString | b64enc | quote }}
  password: {{ default (derivePassword 1 "maximum" (toString (default .Values.auth.masterPassword .Values.auth.secretSeed)) (default "administrator" .Values.auth.userName) .Release.Name) .Values.auth.password | toString | b64enc | quote }}
{{- end -}}{{/* define */}}
