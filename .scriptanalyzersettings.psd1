@{
    ExcludeRules = @(
        # Write-Host is intentional for colored console output in profile/installer
        'PSAvoidUsingWriteHost'
        # Trailing whitespace is handled by editor formatting
        'PSAvoidTrailingWhitespace'
        # Private helper functions use _prefix naming, not approved verbs
        'PSUseApprovedVerbs'
        # gp calls our custom function after Remove-Item Alias:gp
        'PSAvoidUsingCmdletAliases'
    )
}
