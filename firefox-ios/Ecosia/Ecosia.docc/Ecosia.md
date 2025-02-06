# ``Ecosia``

The Ecosia Framework aims to be a wrapper of all our Ecosia isolated implementation and logic.
Some of the Ecosia codebase still lives under the main project `Client/Ecosia` but the goal is to bring as much codebase as possible as part of this dedicated framework.

## Architectural Decision records

Architectural Decision Records (or ADRs) are a method of documenting important decisions a software team makes, and why the decisions were made. They are similar, but complementary to RFCs (requests for comment). The purpose of ADRs is to build up a terse and easily searchable log of decisions so future generations of engineers can understand why our systems are the way they are. For more information, see the [ADR site](https://adr.github.io).\
The are listed in numbered order in the [adr](Ecosia/Core/adr/) directory and should follow this [Y-statement-format](Ecosia/Core/adr/0_2021-04-27_Architectural-decision-record-template.md).

### Example

- [1_2021-04-27_File-based-user-data-persistence.md](Core/adr/1_2021-04-27_File-based-user-data-persistence.md)
- [2_2023-06-29_Environment_as_getter.md](Core/adr/2_2023-06-29_Environment_as_getter.md)
