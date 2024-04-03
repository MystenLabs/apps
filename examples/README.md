# Examples

This directory contains simple examples which illustrate how applications could
be used.

## Notes

- All of the examples are for **illustration purposes only** and should not be
published directly. Use them to bootstrap custom application using suifrens, or
as an inspiration source.

- To prevent accidental publishing, the sources in these examples are marked as
`#[test_only]` - make sure you remove the attribute when copying. To run any of
the examples, use `sui move test`.

## Description

- [*suifrens-reader*](./suifrens-reader/) - this simple application showcases how
to import suifrens, how to use the dependency and how to write generic or
explicitly typed functions using suifrens.

- [*capy-fighter*](./capy-fighter/) - this application illustrated how SuiFren's
genes property can be used to build custom logic and how to attach custom,
application-specific keys to the SuiFren.

- [*enhanced-frens*](./enhanced-frens/) - this application illustrates how you can
attach custom data on a suifren, attaching in-game data in any registered SuiFren.
It also has some sample scripts using the Kiosk SDK to register any owned fren in the game.

## Usage

```bash
# use `test` to run any of the examples
sui move test
```
