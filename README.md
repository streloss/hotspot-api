# 📍 Hotspot API

## Загрузка
loadstring(game:HttpGet("https://raw.githubusercontent.com/НИК/hotspot-api/main/hotspot.lua"))()

## Методы
| Метод | Описание |
|---|---|
| `_G.Hotspot.startAuto()` | Авто-слежка за известными игроками |
| `_G.Hotspot.send(userId/player)` | Отправить вебхук вручную |
| `_G.Hotspot.addPlayer(userId, name)` | Добавить игрока в список |
| `_G.Hotspot.setWebhook(url)` | Сменить вебхук |
