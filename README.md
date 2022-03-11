## Bootstrap and run

Duplicate `config/config.template.exs` and rename it to `config/config.exs`,
then change `YOUR BOT TOKEN` to your bot token

```
mix deps.get
mix run --no-halt

# OR if you want to debug the bot do this:

iex -S mix
```

## Note
`flags: 64` is used for ephemeral message in component.

## Flow

A common store flow:
```mermaid
sequenceDiagram
    participant User as User (Client)
    participant Bot
    participant VAPI as Valorant API

    User->>Bot: Request store
    Bot->>VAPI: Attempt login with username and password
    alt is succeed
        VAPI->>Bot: Return token
    else need 2FA
        VAPI->>Bot: 2FA Cookie
        Bot->>User: Request to input 2FA code
        User->>Bot: Send 2FA code
        Bot->>VAPI: Send 2FA code
        VAPI->>Bot: Return token
    end
    Bot->>VAPI: Request store with token and entitlement
    VAPI->>Bot: Return store data
    Bot->>User: Send store data
```

A common, but has Discord API flow in the store flow:
```mermaid
sequenceDiagram
    participant User as User (Client)
    participant DAPI as Discord API
    participant Bot
    participant VAPI as Valorant API

    User->>DAPI: Request store
    DAPI->>Bot: Application command response
    Bot->>VAPI: Attempt login with username and password
    alt is succeed
        VAPI->>Bot: Return token
    else need 2FA
        VAPI->>Bot: 2FA Cookie
        Bot->>DAPI: Request to input 2FA code
        DAPI->>User: Request to input 2FA code
        User->>DAPI: Send 2FA code
        DAPI->>Bot: Response 2FA code
        Bot->>VAPI: Send 2FA code
        VAPI->>Bot: Return token
    end
    Bot->>VAPI: Request store with token and entitlement
    VAPI->>Bot: Return store data
    Bot->>User: Send store data
```
