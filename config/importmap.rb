pin "application"
pin "@rails/activestorage", to: "activestorage.esm.js"
pin "@rails/actioncable", to: "actioncable.esm.js"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"

# use rails importmap:check to check for major version changes
pin "el-transition", to: "https://cdn.jsdelivr.net/npm/el-transition@0/index.min.js"
pin "stimulus-autocomplete", to: "https://cdn.jsdelivr.net/npm/stimulus-autocomplete@3/src/autocomplete.min.js"
pin "highcharts", to: "https://cdn.jsdelivr.net/npm/highcharts@11/es-modules/masters/highcharts.src.min.js"
pin "highcharts-annotations", to: "https://cdn.jsdelivr.net/npm/highcharts@11/es-modules/masters/modules/annotations.src.min.js"
pin "highlight.js", to: "https://cdn.jsdelivr.net/gh/highlightjs/cdn-release@11/build/es/highlight.min.js"
pin "match-sorter", to: "https://cdn.jsdelivr.net/npm/match-sorter@6/dist/match-sorter.esm.min.js"
pin "remove-accents", to: "https://cdn.jsdelivr.net/npm/remove-accents@0.5.0/+esm"

pin_all_from "app/javascript/channels", under: "channels"
pin_all_from "app/javascript/controllers", under: "controllers"
pin_all_from "app/javascript/charts", under: "charts"
pin_all_from "app/javascript/custom", under: "custom"
