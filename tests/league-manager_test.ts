import {
    Clarinet,
    Tx,
    Chain,
    Account,
    types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
    name: "Test season management",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        
        let block = chain.mineBlock([
            Tx.contractCall('league-manager', 'start-new-season', [
                types.ascii("Season 2024")
            ], deployer.address)
        ]);
        
        block.receipts[0].result.expectOk().expectUint(0);
        
        // End season
        let block2 = chain.mineBlock([
            Tx.contractCall('league-manager', 'end-season', [
                types.uint(0)
            ], deployer.address)
        ]);
        
        block2.receipts[0].result.expectOk().expectBool(true);
    }
});

Clarinet.test({
    name: "Test tournament creation and joining",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const team1 = accounts.get('wallet_1')!;
        
        // Start season first
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
        
        // Register team
        let block3 = chain.mineBlock([
            Tx.contractCall('league-manager', 'register-team', [
                types.ascii("Team A")
            ], team1.address)
        ]);
        
        // Join tournament
        let block4 = chain.mineBlock([
            Tx.contractCall('league-manager', 'join-tournament', [
                types.uint(0)
            ], team1.address)
        ]);
        
        block4.receipts[0].result.expectOk();
    }
});
