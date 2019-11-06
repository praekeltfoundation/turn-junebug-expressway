FROM elixir:1.9-alpine
ENV MIX_ENV="prod"
COPY lib lib
COPY config config
COPY priv priv
COPY mix.* ./
RUN mix local.hex --force
RUN mix local.rebar --force
RUN mix deps.get
RUN mix deps.compile

RUN mix compile

ENV PORT=80
EXPOSE 80
CMD [ "mix", "phx.server" ]