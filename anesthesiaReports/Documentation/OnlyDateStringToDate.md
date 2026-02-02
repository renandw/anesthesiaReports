# OnlyDateString → Date (iOS)

## Contexto
O backend envia datas no formato **ISO sem horário** (`yyyy-MM-dd`).
Quando convertidas diretamente para `Date`, o fuso pode deslocar o dia (ex: `2026-01-01` aparece como `2025-12-31`).

---

## Problema
Se o app usa `DateFormatter` sem **timezone fixo**, o iOS aplica o fuso local e pode deslocar o dia.

---

## Solução adotada
Sempre interpretar e formatar datas ISO **com timezone UTC**, usando `DateFormatterHelper`.

### Regras
- Parse sempre usando `DateFormatterHelper.parseISODate`.
- Para exibir, usar `DateFormatterHelper.formatISODateString`.
- Nunca usar `DateFormatter` direto em views para datas ISO.

---

## Onde aplicado
Exibição de nascimento em:
- `PatientDetailView`
- `PatientRowView`

---

## Observação
Quando a data vem sem hora, ela deve ser tratada como “data pura”, não como horário local.
