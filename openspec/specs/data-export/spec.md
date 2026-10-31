# data-export Specification

## Purpose
TBD - created by archiving change fix-tracking-stats-numbers. Update Purpose after archive.
## Requirements
### Requirement: Product calories in the JSON export
The JSON export SHALL write each product's `calorie_content` from the product's
calories per 100 g.

#### Scenario: Product with different calories and carbs
- **WHEN** a product has 250 kcal and 40 g of carbs per 100 g
- **THEN** its exported `calorie_content` is 250 and its `carbohydrates` is 40

