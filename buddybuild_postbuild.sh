#!/usr/bin/env bash
chruby 2.3.1
bundle install  
bundle exec danger --fail-on-errors=false  

bash <(curl -s https://codecov.io/bash)
