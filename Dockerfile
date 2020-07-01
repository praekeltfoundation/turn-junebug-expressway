FROM elixir:1.9 as elixir
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

FROM elixir:1.9-alpine
ENV MIX_ENV="prod"
RUN mix local.hex --force
RUN mix local.rebar --force
COPY --from=elixir _build _build
COPY --from=elixir config config
COPY --from=elixir deps deps
COPY --from=elixir lib lib
COPY --from=elixir priv priv
COPY --from=elixir mix.* ./

ENV PORT=80
EXPOSE 80
CMD [ "mix", "phx.server" ]
