{{/* Generate a route match list for IngressRoute */}}
{{- define "home.route_match" -}}
{{- $matchHosts := list -}}
{{- range .Values.home_madtech_cx_hosts }}
  {{- $matchHosts = printf "Host(`%s`)" . | append $matchHosts -}}
{{- end -}}
{{ join " || " $matchHosts }}
{{- end -}}
