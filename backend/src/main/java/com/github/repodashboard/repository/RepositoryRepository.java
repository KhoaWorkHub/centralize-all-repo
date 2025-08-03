package com.github.repodashboard.repository;

import com.github.repodashboard.model.Repository;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;

public interface RepositoryRepository extends JpaRepository<Repository, Long> {
    
    @Query("SELECT r FROM Repository r WHERE " +
           "LOWER(r.name) LIKE LOWER(CONCAT('%', :searchTerm, '%')) OR " +
           "LOWER(r.description) LIKE LOWER(CONCAT('%', :searchTerm, '%'))")
    List<Repository> findBySearchTerm(@Param("searchTerm") String searchTerm);
    
    List<Repository> findByLanguage(String language);
    
    List<Repository> findByIsPrivate(Boolean isPrivate);
    
    List<Repository> findByIsFork(Boolean isFork);
    
    @Query("SELECT DISTINCT r.language FROM Repository r WHERE r.language IS NOT NULL ORDER BY r.language")
    List<String> findDistinctLanguages();
}