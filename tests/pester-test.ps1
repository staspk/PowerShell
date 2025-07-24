BeforeAll {
    # Use existing test files
    $testFilesDir = Join-Path $PSScriptRoot "sample_files"
    
    # Verify test files directory exists
    if (-not (Test-Path $testFilesDir)) {
        throw "Test files directory not found: $testFilesDir"
    }
}

Describe "List::CreateList Method Tests" {
    
    Context "When file does not exist" {
        It "Should return null for non-existent file (test_file_0)" {
            $testFile0 = Join-Path $PSScriptRoot "sample_files" "test_file_0"
            
            $result = [Kozubenko.Utils.List]::CreateList($testFile0)
            
            $result | Should -BeNullOrEmpty
            $result | Should -Be $null
        }
    }

    Context "When file exists but has no valid content" {
        It "Should return null for truly empty file (test_file_1)" {
            $testFile1 = Join-Path $PSScriptRoot "sample_files" "test_file_1"
            
            $result = [Kozubenko.Utils.List]::CreateList($testFile1)
            
            $result | Should -BeNullOrEmpty
            $result | Should -Be $null
        }

        It "Should return null for file with only empty lines (test_file_2)" {
            $testFile2 = Join-Path $PSScriptRoot "sample_file" "test_file_2"
            
            $result = [Kozubenko.Utils.List]::CreateList($testFile2)
            
            $result | Should -BeNullOrEmpty
            $result | Should -Be $null
        }
    }

    Context "When file has valid content" {
        It "Should return List[string] with 4 items for test_file_3" {
            $testFile3 = Join-Path $PSScriptRoot "sample_files" "test_file_3"
            
            $result = [Kozubenko.Utils.List]::CreateList($testFile3)
            
            # Test that result is not null and is truthy
            $result | Should -Not -BeNullOrEmpty
            (-not $result) | Should -Be $false
            
            # Test that it's the correct type
            $result | Should -BeOfType [System.Collections.Generic.List[string]]
            
            # Test that it has exactly 4 items
            $result.Count | Should -Be 4
            
            # Verify the content structure
            $result[0] | Should -Be "This is line 1"
            $result[1] | Should -Match "^\s+$"  # Whitespace line
            $result[2] | Should -Be "This is line 3"
            $result[3] | Should -Be ""  # Empty line
        }

        It "Should be mutable (can add/remove items)" {
            $testFile3 = Join-Path $PSScriptRoot "sample_files" "test_file_3"
            
            $result = [Kozubenko.Utils.List]::CreateList($testFile3)
            $originalCount = $result.Count
            
            # Test mutability - add item
            $result.Add("New item")
            $result.Count | Should -Be ($originalCount + 1)
            
            # Test mutability - remove item
            $result.RemoveAt(0)
            $result.Count | Should -Be $originalCount
        }
    }

    Context "Edge cases and validation" {
        It "Should handle empty string path" {
            $result = [Kozubenko.Utils.List]::CreateList("")
            $result | Should -Be $null
        }

        It "Should handle null path" {
            $result = [Kozubenko.Utils.List]::CreateList($null)
            $result | Should -Be $null
        }

        It "Should safely work with -not() operator for null results" {
            $testFile0 = Join-Path $PSScriptRoot "sample_files" "test_file_0"
            $testFile1 = Join-Path $PSScriptRoot "sample_files" "test_file_1"
            $testFile2 = Join-Path $PSScriptRoot "sample_files" "test_file_2"
            
            $result0 = [Kozubenko.Utils.List]::CreateList($testFile0)
            $result1 = [Kozubenko.Utils.List]::CreateList($testFile1)
            $result2 = [Kozubenko.Utils.List]::CreateList($testFile2)
            
            # These should all be truthy when using -not()
            (-not $result0) | Should -Be $true
            (-not $result1) | Should -Be $true
            (-not $result2) | Should -Be $true
        }

        It "Should safely work with -not() operator for valid results" {
            $testFile3 = Join-Path $PSScriptRoot "sample_files" "test_file_3"
            
            $result3 = [Kozubenko.Utils.List]::CreateList($testFile3)
            
            # This should be falsy when using -not()
            (-not $result3) | Should -Be $false
        }
    }

    Context "File content verification" {
        It "Should preserve all lines including empty and whitespace-only lines" {
            $testFile3 = Join-Path $PSScriptRoot "sample_files" "test_file_3"
            
            # Verify our test file setup
            $rawContent = Get-Content -Path $testFile3 -Raw
            $rawContent | Should -Not -BeNullOrEmpty
            
            $result = [Kozubenko.Utils.List]::CreateList($testFile3)
            
            # Should contain both content lines and empty/whitespace lines
            $contentLines = $result | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
            $contentLines.Count | Should -BeGreaterThan 0
            
            $emptyOrWhitespaceLines = $result | Where-Object { [string]::IsNullOrWhiteSpace($_) }
            $emptyOrWhitespaceLines.Count | Should -BeGreaterThan 0
        }
    }
}