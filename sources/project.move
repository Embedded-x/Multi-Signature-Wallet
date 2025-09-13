module MyModule::MultiSigWallet {
    use aptos_framework::signer;
    use aptos_framework::coin;
    use aptos_framework::aptos_coin::AptosCoin;
    use std::vector;

    /// Struct representing a multi-signature wallet
    struct MultiSigWallet has store, key {
        owners: vector<address>,        // List of wallet owners
        required_signatures: u64,       // Number of signatures required
        balance: u64,                   // Current wallet balance
        pending_transactions: vector<Transaction>, // Pending transactions
    }

    /// Struct representing a pending transaction
    struct Transaction has store, drop, copy {
        to: address,                    // Recipient address
        amount: u64,                    // Amount to transfer
        signatures: vector<address>,    // Addresses that have signed
        executed: bool,                 // Whether transaction is executed
    }

    /// Function to create a new multi-signature wallet
    public fun create_multisig_wallet(
        creator: &signer, 
        owners: vector<address>, 
        required_signatures: u64
    ) {
        let wallet = MultiSigWallet {
            owners,
            required_signatures,
            balance: 0,
            pending_transactions: vector::empty<Transaction>(),
        };
        move_to(creator, wallet);
    }

    /// Function to propose and execute transactions with multi-signature approval
    public fun propose_transaction(
        signer_ref: &signer,
        wallet_owner: address,
        to: address,
        amount: u64
    ) acquires MultiSigWallet {
        let wallet = borrow_global_mut<MultiSigWallet>(wallet_owner);
        let signer_addr = signer::address_of(signer_ref);
        
        // Check if signer is an owner
        assert!(vector::contains(&wallet.owners, &signer_addr), 1);
        
        // Create new transaction
        let transaction = Transaction {
            to,
            amount,
            signatures: vector::singleton(signer_addr),
            executed: false,
        };
        
        // If we have enough signatures, execute immediately
        if (vector::length(&transaction.signatures) >= wallet.required_signatures) {
            // Transfer funds
            let payment = coin::withdraw<AptosCoin>(signer_ref, amount);
            coin::deposit<AptosCoin>(to, payment);
            transaction.executed = true;
        };
        
        vector::push_back(&mut wallet.pending_transactions, transaction);
    }
}