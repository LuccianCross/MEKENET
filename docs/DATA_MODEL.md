# Mekenet Data Model

## Transaction

A Transaction represents a financial transaction detected or recorded by the Mekenet application.

| Field | Type | Required | Description |
|---|---|---|---|
| id | String | Yes | Unique identifier for the transaction |
| direction | String | Yes | Indicates whether money came in or went out |
| amount | double | Yes | Monetary amount of the transaction |
| source | String | Yes | Source of the transaction, such as SMS |
| rawSmsHash | String | Yes | Hash used to identify the original SMS without storing its raw content |
| counterpartyMasked | String | Yes | Masked name/identifier of the other party |
| itemId | String? | No | Optional identifier of the related item |
| matchConfidence | String | Yes | Confidence level of the transaction matching/parsing |
| category | String? | No | Optional transaction category |
| timestamp | DateTime | Yes | Date and time when the transaction occurred |
| synced | bool | Yes | Indicates whether the transaction has been synchronized |

### Transaction requirements

- `id` must uniquely identify a transaction.
- `amount` stores the transaction value.
- `direction` distinguishes money coming in from money going out.
- `timestamp` records when the transaction occurred.
- `rawSmsHash` allows duplicate detection without storing the original SMS content.
- `counterpartyMasked` avoids storing the counterparty's full identifying information.
- `itemId` and `category` are optional because not every transaction will have them.
- `synced` tracks synchronization state for the offline-first architecture.

---

## Debt

A Debt represents money owed by a customer.

| Field | Type | Required | Description |
|---|---|---|---|
| id | String | Yes | Unique identifier for the debt |
| customerName | String | Yes | Name of the customer |
| amount | double | Yes | Amount owed |
| status | String | Yes | Current status of the debt |
| createdAt | DateTime | Yes | Date and time when the debt was created |

### Debt requirements

- `id` must uniquely identify a debt.
- `amount` stores the amount currently associated with the debt.
- `status` represents the current state of the debt.
- `createdAt` records when the debt was created.