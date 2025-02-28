import {
    Clarinet,
    Tx,
    Chain,
    Account,
    types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
    name: "Test enhanced tournament management",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const team1 = accounts.get('wallet_1')!;
        
        // Start season
        let block1 = chain.mineBlock([
            Tx.contractCall('league-manager', 'start-new-season', [
                types.ascii("Season 2024")
            ], deployer.address)
        ]);
        
        // Create tournament
        let block2 = chain.mineBlock([
            Tx.contractCall('league-manager', 'create-tournament', [
                types.ascii("Summer Cup")
            ], deployer.address)
        ]);
        
        block2.receipts[0].result.expectOk().expectUint(0);
        
        // Register and join tournament
        let block3 = chain.mineBlock([
            Tx.contractCall('league-manager', 'register-team', [
                types.ascii("Team A")
            ], team1.address),
            Tx.contractCall('league-manager', 'join-tournament', [
                types.uint(0)
            ], team1.address)
        ]);
        
        // Advance tournament round
        let block4 = chain.mineBlock([
            Tx.contractCall('league-manager', 'advance-tournament-round', [
                types.uint(0)
            ], deployer.address)
        ]);
        
        block4.receipts[0].result.expectOk();
    }
});

// [Rest of the original test cases remain unchanged]
