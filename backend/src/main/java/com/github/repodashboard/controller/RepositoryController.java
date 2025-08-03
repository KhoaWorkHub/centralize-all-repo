package com.github.repodashboard.controller;

import com.github.repodashboard.model.Repository;
import com.github.repodashboard.service.GitHubService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api")
@CrossOrigin(origins = "http://localhost:3000")
public class RepositoryController {

    private final GitHubService gitHubService;

    public RepositoryController(GitHubService gitHubService) {
        this.gitHubService = gitHubService;
    }

    @GetMapping("/repos")
    public ResponseEntity<List<Repository>> getAllRepositories(
            @RequestParam(required = false) String search,
            @RequestParam(required = false) String language) {
        
        List<Repository> repositories;
        
        if (search != null && !search.trim().isEmpty()) {
            repositories = gitHubService.searchRepositories(search);
        } else if (language != null && !language.trim().isEmpty()) {
            repositories = gitHubService.filterByLanguage(language);
        } else {
            repositories = gitHubService.getAllRepositories();
        }
        
        return ResponseEntity.ok(repositories);
    }

    @PostMapping("/repos/refresh")
    public ResponseEntity<List<Repository>> refreshRepositories() {
        List<Repository> repositories = gitHubService.fetchAndCacheRepositories();
        return ResponseEntity.ok(repositories);
    }

    @GetMapping("/repos/languages")
    public ResponseEntity<List<String>> getAvailableLanguages() {
        List<String> languages = gitHubService.getAvailableLanguages();
        return ResponseEntity.ok(languages);
    }

    @GetMapping("/repos/stats")
    public ResponseEntity<Map<String, Object>> getRepositoryStats() {
        List<Repository> repositories = gitHubService.getAllRepositories();
        
        int totalRepos = repositories.size();
        int publicRepos = (int) repositories.stream().filter(repo -> !repo.getIsPrivate()).count();
        int privateRepos = (int) repositories.stream().filter(Repository::getIsPrivate).count();
        int forkedRepos = (int) repositories.stream().filter(Repository::getIsFork).count();
        int totalStars = repositories.stream().mapToInt(Repository::getStargazersCount).sum();
        int totalForks = repositories.stream().mapToInt(Repository::getForksCount).sum();
        
        Map<String, Object> stats = Map.of(
            "totalRepositories", totalRepos,
            "publicRepositories", publicRepos,
            "privateRepositories", privateRepos,
            "forkedRepositories", forkedRepos,
            "totalStars", totalStars,
            "totalForks", totalForks
        );
        
        return ResponseEntity.ok(stats);
    }
}