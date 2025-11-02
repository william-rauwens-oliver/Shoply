package com.shoply.app.core

import android.util.Log
import com.google.gson.Gson
import com.google.gson.reflect.TypeToken
import com.shoply.app.models.Outfit
import com.shoply.app.models.WardrobeItem
import com.shoply.app.models.UserProfile

/**
 * Bridge Kotlin → Swift
 * MINIMUM de Kotlin nécessaire pour appeler le code Swift
 */
object ShoplyCore {
    private const val TAG = "ShoplyCore"
    private val gson = Gson()
    
    init {
        try {
            System.loadLibrary("ShoplyCore")
            Log.d(TAG, "✅ Bibliothèque Swift chargée")
        } catch (e: UnsatisfiedLinkError) {
            Log.e(TAG, "❌ Erreur chargement bibliothèque Swift: ${e.message}")
        }
    }
    
    // MARK: - JNI Functions (appellent le code Swift)
    
    private external fun loadOutfits(): String?
    private external fun toggleFavorite(outfitId: String): Boolean
    private external fun getOutfitsFor(mood: String, weather: String): String?
    private external fun getWardrobeItems(): String?
    private external fun addWardrobeItem(itemJson: String): Boolean
    private external fun loadUserProfile(): String?
    private external fun saveUserProfile(profileJson: String): Boolean
    private external fun hasCompletedOnboarding(): Boolean
    
    // MARK: - OutfitService Wrappers
    
    fun getAllOutfits(): List<Outfit> {
        return try {
            val json = loadOutfits() ?: return emptyList()
            val type = object : TypeToken<List<Outfit>>() {}.type
            gson.fromJson(json, type) ?: emptyList()
        } catch (e: Exception) {
            Log.e(TAG, "Erreur chargement outfits", e)
            emptyList()
        }
    }
    
    fun toggleOutfitFavorite(outfit: Outfit): Boolean {
        return try {
            toggleFavorite(outfit.id.toString())
        } catch (e: Exception) {
            Log.e(TAG, "Erreur toggle favorite", e)
            false
        }
    }
    
    fun getOutfitsFiltered(mood: String, weather: String): List<Outfit> {
        return try {
            val json = getOutfitsFor(mood, weather) ?: return emptyList()
            val type = object : TypeToken<List<Outfit>>() {}.type
            gson.fromJson(json, type) ?: emptyList()
        } catch (e: Exception) {
            Log.e(TAG, "Erreur filtrage outfits", e)
            emptyList()
        }
    }
    
    // MARK: - WardrobeService Wrappers
    
    fun getWardrobeItems(): List<WardrobeItem> {
        return try {
            val json = getWardrobeItems() ?: return emptyList()
            val type = object : TypeToken<List<WardrobeItem>>() {}.type
            gson.fromJson(json, type) ?: emptyList()
        } catch (e: Exception) {
            Log.e(TAG, "Erreur chargement garde-robe", e)
            emptyList()
        }
    }
    
    fun addWardrobeItem(item: WardrobeItem): Boolean {
        return try {
            val json = gson.toJson(item)
            addWardrobeItem(json)
        } catch (e: Exception) {
            Log.e(TAG, "Erreur ajout item garde-robe", e)
            false
        }
    }
    
    // MARK: - DataManager Wrappers
    
    fun getUserProfile(): UserProfile? {
        return try {
            val json = loadUserProfile() ?: return null
            gson.fromJson(json, UserProfile::class.java)
        } catch (e: Exception) {
            Log.e(TAG, "Erreur chargement profil", e)
            null
        }
    }
    
    fun saveUserProfile(profile: UserProfile): Boolean {
        return try {
            val json = gson.toJson(profile)
            saveUserProfile(json)
        } catch (e: Exception) {
            Log.e(TAG, "Erreur sauvegarde profil", e)
            false
        }
    }
    
    fun isOnboardingCompleted(): Boolean {
        return try {
            hasCompletedOnboarding()
        } catch (e: Exception) {
            Log.e(TAG, "Erreur vérification onboarding", e)
            false
        }
    }
}

