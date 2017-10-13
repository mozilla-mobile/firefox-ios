#!/usr/bin/env bash
bundle install  
bundle exec danger --fail-on-errors=false  

bash <(curl -s https://codecov.io/bash)
