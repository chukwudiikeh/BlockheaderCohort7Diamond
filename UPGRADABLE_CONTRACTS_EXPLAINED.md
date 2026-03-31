# Upgradable Smart Contracts (ELI5)

Think of a regular smart contract like a house built from concrete - once it's built, you can't change the walls or add new rooms. If you find a bug or want new features, you have to abandon it and build a completely new house.

Upgradable contracts are like having a house where you can swap out rooms while people are still living in it. The address stays the same, but you can change what's inside.

## How Regular Upgradable Contracts Work

The most common pattern uses two contracts:

1. **Proxy Contract** (the permanent address) - This is like your house's address. It never changes. When someone calls a function, it forwards the call somewhere else.

2. **Implementation Contract** (the logic) - This contains your actual code. You can point the proxy to a new implementation anytime.

When you want to upgrade:
- Deploy new implementation contract
- Tell the proxy to use the new address
- Users keep using the same proxy address, but now they're running new code

**Problem**: You're limited by the size of a single contract (24KB). For complex dApps, this isn't enough.

---

# Diamond Standard (EIP-2535)

Diamonds solve the size problem by letting you split your contract into multiple pieces called **facets**.

## The Diamond Analogy

Imagine a diamond (the gem):
- The **diamond itself** is the main contract with one permanent address
- Each **facet** (the flat surfaces on a diamond) is a separate contract with specific functions
- Light (function calls) hits the diamond and gets directed to the right facet

## How Diamonds Work

**1. Diamond Contract (DiamondProxy)**
- Has the permanent address users interact with
- Stores all the data (state variables)
- Contains a mapping: `function selector → facet address`
- When you call a function, it looks up which facet handles it and delegates the call there

**2. Facets (separate contracts)**
- Each facet contains a group of related functions
- Example facets in your project:
  - `DiamondCutFacet` - handles upgrades
  - `DiamondLoupeFacet` - lets you inspect which facets/functions exist
  - Your custom facets with business logic

**3. Function Selectors**
- Each function has a unique 4-byte identifier (selector)
- Example: `transfer(address,uint256)` → `0xa9059cbb`
- The diamond maps these selectors to facet addresses

## Upgrading a Diamond

You can:
- **Add** new functions (add new facets or extend existing ones)
- **Replace** existing functions (point selectors to new facet addresses)
- **Remove** functions (delete selector mappings)

All without changing the diamond's address or losing stored data.

## Key Benefits

1. **No size limit** - Split your code across unlimited facets
2. **Modular upgrades** - Only upgrade the facets you need to change
3. **Shared state** - All facets access the same storage in the diamond
4. **Single address** - Users only interact with one contract address

## In Your Project

Looking at your setup:
- The diamond gets deployed with initial facets
- `DiamondCutFacet` lets you add/replace/remove facets later
- `DiamondLoupeFacet` lets anyone see what functions are available
- You can add custom facets for your dApp's features

The beauty is you can keep adding features forever without redeploying or migrating user data.
