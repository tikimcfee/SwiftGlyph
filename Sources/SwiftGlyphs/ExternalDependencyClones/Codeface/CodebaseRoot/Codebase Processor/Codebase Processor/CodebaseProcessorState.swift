import SwiftLSP

enum CodebaseProcessorState
{
    case empty,
         didLocateCodebase(LSP.CodebaseLocation),
         retrieveCodebase(String),
         didJustRetrieveCodebase(CodeFolder),
         processCodebase(CodeFolder, ProgressFeedback),
         processArchitecture(CodeFolder, ProgressFeedback),
         didFail(String)
    
    struct ProgressFeedback
    {
        let primaryText: String
        let secondaryText: String
    }
}
