# FiscalEngine

A decentralized automated tax calculation smart contract built on Stacks blockchain using Clarity language. FiscalEngine provides real-time tax calculations, compliance tracking, and automated payment processing for individuals and businesses across multiple jurisdictions.

## 💼 Overview

FiscalEngine revolutionizes tax compliance in the blockchain space by automating complex tax calculations for various transaction types. The protocol supports multiple jurisdictions, tax types, and provides comprehensive tracking for both individual transactions and annual filing requirements.

## 🌟 Features

- **Multi-Jurisdiction Support**: US, EU, UK tax calculations with jurisdiction-specific rates
- **Real-Time Tax Calculation**: Instant tax computation for any transaction amount
- **Multiple Tax Types**: Income tax, capital gains tax, and transaction tax support
- **Automated Payment Processing**: STX-based tax payment collection and tracking
- **Annual Filing System**: Complete tax return processing and historical summaries
- **Compliance Tracking**: Monitor taxpayer status and filing requirements
- **Threshold-Based Calculations**: Progressive tax rates based on income levels
- **Administrative Controls**: Dynamic tax rate updates and system management

## 📁 Project Structure

```
fiscal-engine/
├── contracts/
│   └── tax-calculator.clar            # Main automated tax calculation contract
├── tests/
│   └── tax-calculator_test.ts         # Comprehensive contract test suite
├── settings/
│   ├── Devnet.toml                    # Development network configuration
│   ├── Testnet.toml                   # Testnet configuration
│   └── Mainnet.toml                   # Mainnet configuration
├── scripts/
│   ├── deploy.js                      # Deployment automation script
│   └── tax-rate-updater.js            # Tax rate management utility
├── docs/
│   ├── API.md                         # Contract API documentation
│   ├── TAX_RATES.md                   # Tax rate reference guide
│   └── COMPLIANCE.md                  # Legal compliance documentation
├── Clarinet.toml                      # Project configuration
├── README.md                          # This file
└── .gitignore                         # Git ignore rules
```

## 🔧 Smart Contract Details

### Contract Name: `tax-calculator`

### Supported Jurisdictions & Tax Types

| Jurisdiction | Income Tax | Capital Gains | Transaction Tax |
|--------------|------------|---------------|-----------------|
| US | 22% | 15% | 0.25% |
| EU | Variable | Variable | Variable |
| UK | Variable | Variable | Variable |

### Core Functions

#### Public Functions

**`register-taxpayer`**
- Register user in the tax system with jurisdiction selection
- Required before performing any tax calculations
- Parameters: `jurisdiction` (uint: 1=US, 2=EU, 3=UK)

**`calculate-tax`**
- Calculate tax for a specific transaction amount and type
- Returns calculation ID, tax amount, and net amount
- Parameters: `amount` (uint), `tax-type` (uint: 1=Income, 2=Capital Gains, 3=Transaction)

**`pay-tax`**
- Process tax payment for a calculated tax obligation
- Transfers STX from user to contract treasury
- Parameters: `calculation-id` (uint)

**`file-annual-return`**
- File complete annual tax return with income and capital gains
- Generates comprehensive tax summary for the year
- Parameters: `tax-year` (uint), `total-income` (uint), `total-capital-gains` (uint)

**`update-tax-rate`** (Admin Only)
- Update tax rates for specific jurisdiction and tax type
- Parameters: `jurisdiction` (uint), `tax-type` (uint), `new-rate` (uint), `threshold` (uint)

#### Read-Only Functions

**`get-calculation`**
- Retrieve detailed information about a specific tax calculation
- Parameters: `calculation-id` (uint)
- Returns: Complete calculation details including amounts and payment status

**`get-taxpayer-info`**
- Get comprehensive taxpayer profile and statistics
- Parameters: `taxpayer` (principal)
- Returns: Jurisdiction, totals, compliance status, filing history

**`get-annual-summary`**
- Retrieve annual tax summary for specific taxpayer and year
- Parameters: `taxpayer` (principal), `tax-year` (uint)
- Returns: Annual income, taxes owed, taxes paid, filing status

**`get-tax-rate`**
- Get current tax rate for jurisdiction and tax type
- Parameters: `jurisdiction` (uint), `tax-type` (uint)
- Returns: Current rate, threshold, last update block

**`estimate-tax`**
- Preview tax calculation without creating formal calculation
- Parameters: `amount` (uint), `jurisdiction` (uint), `tax-type` (uint)
- Returns: Estimated tax amount and net amount

**`get-contract-stats`**
- Get overall contract statistics and metrics
- Returns: Total calculations, tax collected, current tax year

### Data Maps

**`tax-calculations`**
- Stores individual tax calculation records
- Key: `{ calculation-id: uint }`
- Value: Taxpayer, amounts, rates, dates, payment status

**`tax-rates`**
- Maintains current tax rates by jurisdiction and type
- Key: `{ jurisdiction: uint, tax-type: uint }`
- Value: Rate, threshold, update timestamp

**`taxpayers`**
- Comprehensive taxpayer profiles and statistics
- Key: `{ taxpayer: principal }`
- Value: Jurisdiction, totals, compliance status, filing history

**`annual-summaries`**
- Annual tax filing summaries and records
- Key: `{ taxpayer: principal, tax-year: uint }`
- Value: Annual totals, tax obligations, filing status

## 🔒 Security Features

- **Amount Validation**: Ensures positive amounts and reasonable limits
- **Authorization Checks**: Taxpayer-specific access controls
- **Duplicate Prevention**: Prevents double payments and duplicate filings
- **Jurisdiction Validation**: Validates supported jurisdictions
- **Admin Controls**: Secure tax rate management with owner verification
- **Payment Verification**: STX balance checks before processing payments

## 💰 Economic Model

### Tax Rate Structure
- **Progressive Rates**: Different rates based on income thresholds
- **Type-Specific**: Separate rates for income, capital gains, transactions
- **Jurisdiction-Based**: Localized tax rates reflecting real-world systems
- **Dynamic Updates**: Admin-controlled rate adjustments

### Treasury Management
- **Automated Collection**: Smart contract handles all tax payments
- **Transparent Tracking**: Complete audit trail of all transactions
- **Compliance Integration**: Links payments to specific tax obligations
- **Statistical Reporting**: Aggregate data for analysis and reporting

## 🚀 Getting Started

### Prerequisites
- [Clarinet](https://github.com/hirosystems/clarinet) installed
- Node.js and npm/yarn for scripts
- Stacks wallet with STX tokens
- Basic understanding of tax concepts

### Installation

1. Clone the repository:
```bash
git clone https://github.com/your-org/fiscal-engine
cd fiscal-engine
```

2. Install dependencies:
```bash
clarinet install
npm install
```

3. Run tests:
```bash
clarinet test
```

4. Check contract syntax:
```bash
clarinet check
```

### Quick Start

1. **Register as Taxpayer**:
```bash
clarinet console
>> (contract-call? .tax-calculator register-taxpayer u1)
```

2. **Calculate Tax**:
```bash
>> (contract-call? .tax-calculator calculate-tax u1000000 u1)
```

3. **Pay Tax**:
```bash
>> (contract-call? .tax-calculator pay-tax u1)
```

### Deployment

#### Devnet
```bash
npm run deploy:devnet
```

#### Testnet
```bash
npm run deploy:testnet
```

#### Mainnet
```bash
npm run deploy:mainnet
```

## 🧪 Testing

Run comprehensive tests covering all tax scenarios:

```bash
# Run all tests
clarinet test

# Run specific test categories
clarinet test tests/tax-calculator_test.ts

# Run with detailed coverage
clarinet test --coverage

# Performance testing
npm run test:performance
```

### Test Coverage
- Tax calculation accuracy across all types
- Multi-jurisdiction rate applications
- Payment processing and tracking
- Annual filing workflows
- Administrative functions
- Error handling and edge cases

## 📝 Usage Examples

### Basic Tax Calculation Workflow
```clarity
;; 1. Register as taxpayer
(contract-call? .tax-calculator register-taxpayer u1)

;; 2. Calculate income tax on $10,000
(contract-call? .tax-calculator calculate-tax u10000000000 u1)

;; 3. Pay the calculated tax
(contract-call? .tax-calculator pay-tax u1)

;; 4. Check calculation details
(contract-call? .tax-calculator get-calculation u1)
```

### Annual Filing Example
```clarity
;; File annual return for 2024
(contract-call? .tax-calculator file-annual-return 
  u2024 
  u50000000000  ;; $50,000 income
  u10000000000) ;; $10,000 capital gains

;; Check annual summary
(contract-call? .tax-calculator get-annual-summary 'SP1ABC... u2024)
```

### Tax Estimation
```clarity
;; Estimate tax before committing
(contract-call? .tax-calculator estimate-tax u5000000000 u1 u2)
```

## 🎯 Use Cases

### Individual Users
- **Crypto Traders**: Automated capital gains calculations
- **DeFi Users**: Transaction tax tracking
- **Remote Workers**: Multi-jurisdiction income tax
- **Investors**: Portfolio tax optimization

### Business Applications
- **DeFi Protocols**: Integrated tax compliance
- **Crypto Exchanges**: User tax reporting
- **Payment Processors**: Transaction tax automation
- **Accounting Firms**: Client tax management

### Enterprise Solutions
- **Multinational Corps**: Cross-border tax calculation
- **Payroll Systems**: Employee tax automation
- **Treasury Management**: Corporate tax compliance
- **Audit Systems**: Tax verification and reporting

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/tax-feature`)
3. Commit your changes (`git commit -m 'Add tax feature'`)
4. Push to the branch (`git push origin feature/tax-feature`)
5. Open a Pull Request

### Development Guidelines
- Follow tax calculation best practices
- Add comprehensive tests for new jurisdictions
- Update rate tables for accuracy
- Ensure compliance with local regulations
- Document all tax logic thoroughly

## 📊 Error Codes

| Code | Constant | Description |
|------|----------|-------------|
| 100 | ERR-NOT-AUTHORIZED | Unauthorized access or operation |
| 101 | ERR-INVALID-JURISDICTION | Unsupported or invalid jurisdiction |
| 102 | ERR-INVALID-AMOUNT | Invalid amount (negative or zero) |
| 103 | ERR-INVALID-TAX-TYPE | Unsupported tax type |
| 104 | ERR-ALREADY-CALCULATED | Tax already paid for this calculation |
| 105 | ERR-CALCULATION-NOT-FOUND | Tax calculation ID not found |

## 🗺️ Roadmap

### Phase 1: Core Implementation ✅
- Basic tax calculation engine
- Multi-jurisdiction support
- Payment processing
- Annual filing system

### Phase 2: Advanced Features 🚧
- Deduction management system
- Tax loss harvesting automation
- Quarterly payment scheduling
- Multi-currency support

### Phase 3: Integration & APIs 📋
- External tax service integration
- RESTful API endpoints
- Third-party accounting software plugins
- Mobile app development

### Phase 4: AI & Analytics 🌟
- Machine learning tax optimization
- Predictive compliance alerts
- Advanced reporting dashboards
- Regulatory change notifications

## 🔮 Future Enhancements

- **Deduction Tracking**: Automated expense and deduction management
- **Tax Loss Harvesting**: Intelligent loss realization for optimization
- **Regulatory Updates**: Automated tax law change integration
- **Audit Support**: Comprehensive audit trail and documentation
- **Cross-Chain Support**: Multi-blockchain tax calculation
- **Integration Hub**: Connect with popular accounting and tax software

## ⚖️ Legal Disclaimer

**Important**: This smart contract is for educational and demonstration purposes. Tax laws are complex and vary by jurisdiction. Always consult with qualified tax professionals and ensure compliance with local regulations before using any automated tax system in production.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Tax law research and compliance experts
- Stacks Foundation for blockchain infrastructure
- Clarity language documentation and community
- Open-source tax calculation libraries
- Regulatory compliance frameworks

## 📞 Support

- **Documentation**: [Comprehensive API Docs](docs/API.md)
- **Tax Rates**: [Current Rate Tables](docs/TAX_RATES.md)
- **Compliance**: [Legal Guidelines](docs/COMPLIANCE.md)
- **Community**: [Discord Support Channel](https://discord.gg/fiscal-engine)
- **Issues**: Create an issue on GitHub
- **Professional**: tax-support@fiscalengine.io