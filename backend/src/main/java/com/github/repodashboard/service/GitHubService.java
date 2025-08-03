package com.github.repodashboard.service;

import com.github.repodashboard.dto.GitHubRepository;
import com.github.repodashboard.model.Repository;
import com.github.repodashboard.repository.RepositoryRepository;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.ParameterizedTypeReference;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.web.reactive.function.client.WebClient;
import org.springframework.web.reactive.function.client.WebClientResponseException;
import org.springframework.web.client.RestTemplate;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpMethod;
import org.springframework.http.ResponseEntity;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.stream.Collectors;

@Service
public class GitHubService {

    private final WebClient webClient;
    private final RestTemplate restTemplate;
    private final RepositoryRepository repositoryRepository;
    private final String githubToken;
    private final String baseUrl;

    public GitHubService(@Value("${github.token}") String githubToken,
                        @Value("${github.api.base-url}") String baseUrl,
                        RepositoryRepository repositoryRepository) {
        this.githubToken = githubToken;
        this.baseUrl = baseUrl;
        this.repositoryRepository = repositoryRepository;
        
        System.out.println("Initializing GitHub service with base URL: " + baseUrl);
        System.out.println("GitHub token configured: " + (githubToken != null && !githubToken.isEmpty()));
        
        this.webClient = WebClient.builder()
                .baseUrl(baseUrl)
                .defaultHeader(HttpHeaders.AUTHORIZATION, "Bearer " + githubToken)
                .defaultHeader(HttpHeaders.ACCEPT, MediaType.APPLICATION_JSON_VALUE)
                .defaultHeader(HttpHeaders.USER_AGENT, "GitHub-Repo-Dashboard")
                .codecs(configurer -> configurer.defaultCodecs().maxInMemorySize(2 * 1024 * 1024)) // 2MB buffer
                .build();
                
        this.restTemplate = new RestTemplate();
    }

    public List<Repository> getAllRepositories() {
        List<Repository> cachedRepos = repositoryRepository.findAll();
        if (cachedRepos.isEmpty()) {
            return fetchAndCacheRepositories();
        }
        return cachedRepos;
    }

    public List<Repository> fetchAndCacheRepositories() {
        try {
            System.out.println("Fetching repositories from GitHub API using RestTemplate...");
            
            // Set up headers
            HttpHeaders headers = new HttpHeaders();
            headers.set("Authorization", "Bearer " + githubToken);
            headers.set("Accept", "application/json");
            headers.set("User-Agent", "GitHub-Repo-Dashboard");
            
            HttpEntity<String> entity = new HttpEntity<>(headers);
            
            // Make the request
            String url = baseUrl + "/user/repos?type=all&sort=updated&per_page=100";
            System.out.println("Making request to: " + url);
            
            ResponseEntity<GitHubRepository[]> response = restTemplate.exchange(
                url,
                HttpMethod.GET,
                entity,
                GitHubRepository[].class
            );

            GitHubRepository[] githubReposArray = response.getBody();
            List<GitHubRepository> githubRepos = githubReposArray != null ? 
                List.of(githubReposArray) : List.of();

            System.out.println("Received " + githubRepos.size() + " repositories from GitHub");

            if (!githubRepos.isEmpty()) {
                System.out.println("Converting repositories...");
                List<Repository> repositories = githubRepos.stream()
                        .map(this::convertToRepository)
                        .collect(Collectors.toList());

                System.out.println("Converted " + repositories.size() + " repositories, saving to database...");
                repositoryRepository.deleteAll();
                repositoryRepository.saveAll(repositories);
                System.out.println("Successfully saved repositories to database");
                return repositories;
            } else {
                System.out.println("No repositories received from GitHub API");
            }
        } catch (Exception e) {
            System.err.println("Error fetching repositories from GitHub: " + e.getClass().getName() + " - " + e.getMessage());
            e.printStackTrace();
        }
        
        return repositoryRepository.findAll();
    }

    @Scheduled(fixedRate = 300000) // Refresh every 5 minutes
    public void scheduledRepositoryRefresh() {
        System.out.println("Scheduled refresh of repositories...");
        fetchAndCacheRepositories();
    }

    public List<Repository> searchRepositories(String searchTerm) {
        if (searchTerm == null || searchTerm.trim().isEmpty()) {
            return getAllRepositories();
        }
        return repositoryRepository.findBySearchTerm(searchTerm.trim());
    }

    public List<Repository> filterByLanguage(String language) {
        if (language == null || language.trim().isEmpty()) {
            return getAllRepositories();
        }
        return repositoryRepository.findByLanguage(language);
    }

    public List<String> getAvailableLanguages() {
        return repositoryRepository.findDistinctLanguages();
    }

    private Repository convertToRepository(GitHubRepository githubRepo) {
        Repository repo = new Repository();
        repo.setId(githubRepo.getId());
        repo.setName(githubRepo.getName());
        repo.setFullName(githubRepo.getFullName());
        repo.setDescription(githubRepo.getDescription());
        repo.setHtmlUrl(githubRepo.getHtmlUrl());
        repo.setStargazersCount(githubRepo.getStargazersCount() != null ? githubRepo.getStargazersCount() : 0);
        repo.setForksCount(githubRepo.getForksCount() != null ? githubRepo.getForksCount() : 0);
        repo.setLanguage(githubRepo.getLanguage() != null ? githubRepo.getLanguage() : "Unknown");
        repo.setIsPrivate(githubRepo.getIsPrivate() != null ? githubRepo.getIsPrivate() : false);
        repo.setIsFork(githubRepo.getFork() != null ? githubRepo.getFork() : false);

        // Parse ISO date strings to LocalDateTime (removing Z timezone indicator)
        try {
            String createdAtStr = githubRepo.getCreatedAt();
            String updatedAtStr = githubRepo.getUpdatedAt();
            
            if (createdAtStr != null) {
                createdAtStr = createdAtStr.replace("Z", "");
                repo.setCreatedAt(LocalDateTime.parse(createdAtStr, DateTimeFormatter.ISO_LOCAL_DATE_TIME));
            } else {
                repo.setCreatedAt(LocalDateTime.now());
            }
            
            if (updatedAtStr != null) {
                updatedAtStr = updatedAtStr.replace("Z", "");
                repo.setUpdatedAt(LocalDateTime.parse(updatedAtStr, DateTimeFormatter.ISO_LOCAL_DATE_TIME));
            } else {
                repo.setUpdatedAt(LocalDateTime.now());
            }
        } catch (Exception e) {
            System.err.println("Error parsing dates for repo " + githubRepo.getName() + ": " + e.getMessage());
            e.printStackTrace();
            repo.setCreatedAt(LocalDateTime.now());
            repo.setUpdatedAt(LocalDateTime.now());
        }

        return repo;
    }
}