# Decentralized Escrow Service

A secure smart contract-based escrow service built on the Stacks blockchain using Clarity smart contracts. This service enables safe peer-to-peer transactions by holding funds in escrow until both parties fulfill their obligations.

## Features

- **Secure Fund Holding**: Funds are held safely in the smart contract until release conditions are met
- **Dispute Resolution**: Built-in dispute mechanism with arbitration capabilities
- **Platform Fee System**: Configurable fee structure for service sustainability
- **Multi-party Support**: Supports buyer-seller interactions with clear role definitions
- **Transparent Operations**: All escrow states and transactions are publicly verifiable

## How It Works

1. **Create Escrow**: Buyer creates an escrow by depositing STX tokens and specifying the seller
2. **Active State**: Funds are held securely in the contract until the buyer releases them
3. **Release Funds**: Buyer can release funds to the seller upon satisfaction
4. **Dispute Resolution**: Either party can dispute, triggering manual resolution by contract owner
5. **Fee Collection**: Platform collects a small fee (default 2.5%) on successful transactions

## Contract Functions

### Read-Only Functions
- `get-escrow(escrow-id)`: Retrieve escrow details
- `get-escrow-balance(escrow-id)`: Check escrow balance
- `get-platform-fee-rate()`: Get current platform fee rate
- `calculate-platform-fee(amount)`: Calculate fee for given amount

### Public Functions
- `create-escrow(seller, amount, description)`: Create new escrow
- `release-funds(escrow-id)`: Release funds to seller (buyer only)
- `dispute-escrow(escrow-id, reason)`: Initiate dispute
- `resolve-dispute(escrow-id, release-to-seller)`: Resolve dispute (owner only)
- `set-platform-fee-rate(new-rate)`: Update platform fee (owner only)

## Usage Example

```clarity
;; Create an escrow for 1000 STX
(contract-call? .escrow-service create-escrow 'SP1ABCD... u1000000 "Payment for web development services")

;; Release funds to seller (as buyer)
(contract-call? .escrow-service release-funds u1)

;; Dispute an escrow
(contract-call? .escrow-service dispute-escrow u1 "Services not delivered as agreed")
```

## Security Features

- **Access Control**: Only authorized parties can perform specific actions
- **State Validation**: Prevents invalid state transitions
- **Fund Safety**: Funds are held securely until proper release conditions are met
- **Dispute Protection**: Built-in mechanism to handle disagreements

## Development

This contract is developed using Clarinet for testing and deployment on the Stacks blockchain.

### Prerequisites
- Clarinet CLI
- Stacks wallet for testing

### Testing
```bash
clarinet check
clarinet test
```

## License

MIT License - see LICENSE file for details.

## Contributing

Contributions are welcome! Please feel free to submit pull requests or open issues for improvements.