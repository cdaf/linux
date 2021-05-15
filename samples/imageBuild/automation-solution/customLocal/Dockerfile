# DOCKER-VERSION 1.2.0
# Allow override of image as environment variable
ARG CONTAINER_IMAGE
FROM ${CONTAINER_IMAGE}

ARG proxy
ENV http_proxy=$proxy

ENV RAILS_ENV production
ENV RAILS_SERVE_STATIC_FILES true
ENV RAILS_LOG_TO_STDOUT true

# Copy solution, provision and then build
WORKDIR /solution

# Copy only scripts required as imageBuild.sh will copy all files in automation directory
COPY automation/provisioning/base.sh automation/provisioning/base.sh
COPY automation/remote/capabilities.sh automation/remote/capabilities.sh
COPY bootstrapTarget.sh .
RUN chmod +x bootstrapTarget.sh && ./bootstrapTarget.sh && gem environment

# Install application pre-requisites
WORKDIR /solution/blog
COPY Gemfile .
COPY Gemfile.lock .
RUN bundle config --global frozen 1 && bundle config set without 'development test' && bundle install && rails --version && ls -al

# Create node_modules
COPY yarn.lock .
RUN yarn install && ls -al

# Install application
ADD blog.tar.gz .
RUN bundle exec rake DATABASE_URL=postgresql:does_not_exist SECRET_KEY_BASE=dummy_key_for_precompile assets:precompile && ls -al

EXPOSE 3000

# Bind to all networks
CMD ["rails", "server", "-b", "0.0.0.0"]