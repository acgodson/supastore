// SPDX-License-Identifier: MIT

pragma solidity 0.8.26;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {ISchemaRegistry} from "@ethereum-attestation-service/eas-contracts/contracts/ISchemaRegistry.sol";
import {ISchemaResolver} from "@ethereum-attestation-service/eas-contracts/contracts/resolver/ISchemaResolver.sol";
import {IEAS, AttestationRequest, AttestationRequestData, DelegatedAttestationRequest, Signature, RevocationRequest, RevocationRequestData} from "@ethereum-attestation-service/eas-contracts/contracts/IEAS.sol";
import {NO_EXPIRATION_TIME, EMPTY_UID} from "@ethereum-attestation-service/eas-contracts/contracts/Common.sol";

contract Supastore {
    error InvalidSchemaRegistry();
    error InvalidSchema();
    error InvalidResolver();
    error InvalidEAS();

    // The address of the global SchemaRegistry contract.
    ISchemaRegistry private immutable _schemaRegistry;
    // The address of the global EAS contract.
    IEAS private immutable _eas;

    // Struct to store schema details
    struct SchemaDetail {
        string schema;
        ISchemaResolver resolver;
        bool revocable;
    }

    // Mapping of schema UIDs to their details
    mapping(bytes32 => SchemaDetail) private _schemas;

    // Array to keep track of all schema IDs.
    string[] private schemaList;

    // Event to emit when a new schema is registered.
    event SchemaRegistered(string schemaName, bytes32 schemaId);

    // Event to emit when a new attestation is created.
    event AttestationCreated(
        bytes32 schemaUID,
        bytes32 attestationUID,
        address recipient
    );

    // Constructor
    constructor(ISchemaRegistry schemaRegistry, IEAS eas) {
        if (address(schemaRegistry) == address(0)) {
            revert InvalidSchemaRegistry();
        }

        if (address(eas) == address(0)) {
            revert InvalidEAS();
        }

        _schemaRegistry = schemaRegistry;
        _eas = eas;
    }

    /// @notice Registers a new schema or selects an existing one.
    /// @param schema The schema string to register or select.
    /// @param resolver The resolver for custom interactions (optional).
    /// @param revocable Whether the schema allows revocations.
    /// @return schemaUID The UID of the registered or selected schema.
    function registerSchema(
        string memory schema,
        ISchemaResolver resolver,
        bool revocable
    ) external returns (bytes32 schemaUID) {
        if (bytes(schema).length == 0) {
            revert InvalidSchema();
        }

        // Register the schema if it doesn't exist
        schemaUID = _schemaRegistry.register(schema, resolver, revocable);
        _schemas[schemaUID] = SchemaDetail(schema, resolver, revocable);
        schemaList.push(schema);

        emit SchemaRegistered(schema, schemaUID);
    }

    /// @notice Creates an attestation for a specific schema.
    /// @param schemaUID The UID of the schema to attest to.
    /// @param recipient The recipient of the attestation.
    /// @param data The encoded data related to the attestation.
    /// @return attestationUID The UID of the new attestation.
    function createAttestation(
        bytes32 schemaUID,
        address recipient,
        bytes memory data,
        bytes32 refUID // Added this parameter for referencing another attestation.
    ) external returns (bytes32 attestationUID) {
        require(bytes(_schemas[schemaUID].schema).length > 0, "Invalid schema");

        // Create an attestation
        attestationUID = _eas.attest(
            AttestationRequest({
                schema: schemaUID,
                data: AttestationRequestData({
                    recipient: recipient,
                    expirationTime: NO_EXPIRATION_TIME,
                    revocable: _schemas[schemaUID].revocable,
                    refUID: refUID != bytes32(0) ? refUID : EMPTY_UID, // Dynamic reference handling
                    data: data,
                    value: 0 // No value/ETH
                })
            })
        );

        emit AttestationCreated(schemaUID, attestationUID, recipient);
    }

    /// @notice Creates a delegated attestation with dynamic reference handling.
    /// @param schemaUID The UID of the schema to attest to.
    /// @param recipient The recipient of the attestation.
    /// @param data The encoded data related to the attestation.
    /// @param attester The address of the attester who signed the delegation.
    /// @param signature The ECDSA signature of the attester.
    /// @param deadline The deadline after which the signature is invalid.
    /// @param refUID The UID of the referenced attestation, if applicable.
    /// @return attestationUID The UID of the new attestation.
    function createDelegatedAttestation(
        bytes32 schemaUID,
        address recipient,
        bytes memory data,
        address attester,
        Signature memory signature,
        uint64 deadline,
        bytes32 refUID // Added this parameter for referencing another attestation.
    ) external returns (bytes32 attestationUID) {
        // Validate the schema
        require(bytes(_schemas[schemaUID].schema).length > 0, "Invalid schema");

        // Create a delegated attestation
        attestationUID = _eas.attestByDelegation(
            DelegatedAttestationRequest({
                schema: schemaUID,
                data: AttestationRequestData({
                    recipient: recipient,
                    expirationTime: NO_EXPIRATION_TIME,
                    revocable: _schemas[schemaUID].revocable,
                    refUID: refUID != bytes32(0) ? refUID : EMPTY_UID, // Dynamic reference handling
                    data: data,
                    value: 0 // No value/ETH
                }),
                signature: signature,
                attester: attester,
                deadline: deadline
            })
        );

        emit AttestationCreated(schemaUID, attestationUID, recipient);
    }

    /// @notice Retrieve all schema IDs.
    /// @return A list of all registered schema names.
    function getAllSchemas() external view returns (string[] memory) {
        return schemaList;
    }

    /// @notice Revokes an existing attestation.
    /// @param schemaUID The UID of the schema.
    /// @param attestationUID The UID of the attestation to revoke.
    function revokeAttestation(bytes32 schemaUID, bytes32 attestationUID)
        external
    {
        // Revoke the attestation
        _eas.revoke(
            RevocationRequest({
                schema: schemaUID,
                data: RevocationRequestData({uid: attestationUID, value: 0})
            })
        );
    }
}
