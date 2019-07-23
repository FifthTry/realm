set -e
set -x

mkdir -p build

# ./node_modules/.bin/elm-make src/frontend/All.elm --output builds/e.js

./node_modules/.bin/webpack \
    --config ../../realm/webpack.config.js

#    --optimize-minimize \
#    --define process.env.NODE_ENV="production" \


#cat ../../realm/polyfill.js \
#    builds/bundle.js \
#    builds/e.js \
#    ../../realm/web-post-common.js \
#    ../../realm/web-post-partial.js \
#    | node_modules/uglify-js/bin/uglifyjs \
#        > builds/e2.js
