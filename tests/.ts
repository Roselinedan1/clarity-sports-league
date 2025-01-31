import {
    Clarinet,
    Tx,
    Chain,
    Account,
    types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
    name: "Test team registration",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const wallet1 = accounts.get('wallet_1')!;
        
        let block = chain.mineBlock([
            Tx.contractCall('league-manager', 'register-team', [
                types.ascii("Team A")
            ], wallet1.address)
        ]);
        
        block.receipts[0].result.expectOk();
        
        // Try registering same team again
        let block2 = chain.mineBlock([
            Tx.contractCall('league-manager', 'register-team', [
                types.ascii("Team A")
            ], wallet1.address)
        ]);
        
        block2.receipts[0].result.expectErr(types.uint(101)); // err-team-exists
    }
});

Clarinet.test({
    name: "Test match scheduling and result recording",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const team1 = accounts.get('wallet_1')!;
        const team2 = accounts.get('wallet_2')!;
        
        // Register teams
        let block1 = chain.mineBlock([
            Tx.contractCall('league-manager', 'register-team', [
                types.ascii("Team A")
            ], team1.address),
            Tx.contractCall('league-manager', 'register-team', [
                types.ascii("Team B")
            ], team2.address)
        ]);
        
        // Schedule match
        let block2 = chain.mineBlock([
            Tx.contractCall('league-manager', 'schedule-match', [
                types.principal(team1.address),
                types.principal(team2.address)
            ], deployer.address)
        ]);
        
        block2.receipts[0].result.expectOk();
        
        // Record match result
        let block3 = chain.mineBlock([
            Tx.contractCall('league-manager', 'record-match-result', [
                types.uint(0),
                types.uint(2),
                types.uint(1)
            ], deployer.address)
        ]);
        
        block3.receipts[0].result.expectOk();
    }
});
