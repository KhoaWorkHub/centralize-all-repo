package com.github.repodashboard.controller;

import com.github.repodashboard.service.GitHubService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/webhook")
@CrossOrigin(origins = "*")
public class WebhookController {

    private final GitHubService gitHubService;

    public WebhookController(GitHubService gitHubService) {
        this.gitHubService = gitHubService;
    }

    @PostMapping("/github")
    public ResponseEntity<String> handleGitHubWebhook(
            @RequestHeader("X-GitHub-Event") String eventType,
            @RequestHeader(value = "X-GitHub-Delivery", required = false) String deliveryId,
            @RequestBody Map<String, Object> payload) {
        
        System.out.println("Received GitHub webhook: " + eventType);
        System.out.println("Delivery ID: " + deliveryId);
        
        // Handle repository events
        if ("repository".equals(eventType)) {
            String action = (String) payload.get("action");
            System.out.println("Repository action: " + action);
            
            // Trigger repository refresh for relevant actions
            if ("created".equals(action) || "deleted".equals(action) || 
                "publicized".equals(action) || "privatized".equals(action) ||
                "edited".equals(action)) {
                
                System.out.println("Refreshing repositories due to repository event...");
                gitHubService.fetchAndCacheRepositories();
            }
        }
        
        // Handle push events (in case repository metadata changes)
        else if ("push".equals(eventType)) {
            System.out.println("Received push event, checking for repository updates...");
            gitHubService.fetchAndCacheRepositories();
        }
        
        return ResponseEntity.ok("Webhook processed successfully");
    }

    @GetMapping("/github")
    public ResponseEntity<String> webhookHealthCheck() {
        return ResponseEntity.ok("GitHub webhook endpoint is active");
    }
}